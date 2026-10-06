import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Sugiere los gastos esenciales mensuales para el fondo de emergencia.
final class EssentialExpenseEstimator {
  const new();

  /// Promedio mensual de gastos esenciales en [months].
  Money averageMonthly({
    required List<Transaction> transactions,
    required List<YearMonth> months,
  }) {
    if (months.isEmpty) return Money.zero;
    final total = Money.sum(
      transactions
          .where(
            (t) =>
                t.isExpense &&
                t.nature == ExpenseNature.essential &&
                months.any((m) => m.contains(t.date)),
          )
          .map((t) => t.amount),
    );
    return total.divide(months.length);
  }
}
