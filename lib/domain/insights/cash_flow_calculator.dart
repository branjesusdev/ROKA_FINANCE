import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

final class CashFlow {
  const new({
    required this.income,
    required this.expenses,
    required this.savingContributions,
    this.adjustments = Money.zero,
  });

  /// Ingresos reales (sin ajustes de saldo).
  final Money income;

  /// Dinero que se sumó al cuadrar el saldo (lo que tenías y no estaba
  /// registrado). Cuenta para lo que te queda, no como ingreso.
  final Money adjustments;

  /// Gastos reales: excluye categorías que cuentan como ahorro.
  final Money expenses;

  /// Gastos en categorías de ahorro/inversión.
  final Money savingContributions;

  /// Ahorro del período = ingresos − gastos reales.
  Money get savings => income - expenses;

  /// `null` si no hay ingresos.
  Percentage? get savingsRate => Percentage.ratio(savings, income);

  /// Gastos sobre ingresos. `null` si no hay ingresos.
  Percentage? get expenseRatio => Percentage.ratio(expenses, income);
}

final class CashFlowCalculator {
  const new();

  CashFlow calculate(
    List<Transaction> transactions, {
    required Set<String> savingCategoryIds,
  }) {
    var income = Money.zero;
    var expenses = Money.zero;
    var saving = Money.zero;
    var adjustments = Money.zero;
    for (final t in transactions) {
      if (t.isIncome &&
          t.categoryId == DefaultCategories.balanceAdjustment.id) {
        adjustments += t.amount;
      } else if (t.isIncome) {
        income += t.amount;
      } else if (savingCategoryIds.contains(t.categoryId)) {
        saving += t.amount;
      } else {
        expenses += t.amount;
      }
    }
    return CashFlow(
      income: income,
      expenses: expenses,
      savingContributions: saving,
      adjustments: adjustments,
    );
  }
}
