import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

final class BudgetStatus {
  const new({
    required this.limit,
    required this.spent,
    required this.usage,
    required this.light,
  });

  final Money limit;
  final Money spent;

  /// `null` cuando el límite es cero.
  final Percentage? usage;
  final TrafficLight light;

  /// Negativo cuando se superó el límite.
  Money get available => limit - spent;
  bool get isOverBudget => spent > limit;
}

final class CategoryBudgetStatus {
  const new({required this.categoryId, required this.status});

  final String categoryId;
  final BudgetStatus status;
}

final class MonthBudgetStatus {
  const new({
    required this.period,
    required this.categories,
    required this.total,
  });

  final YearMonth period;
  final List<CategoryBudgetStatus> categories;

  /// Suma solo de las categorías presupuestadas.
  final BudgetStatus total;

  bool get hasBudget => categories.isNotEmpty;

  List<CategoryBudgetStatus> get overBudget =>
      categories.where((c) => c.status.isOverBudget).toList();
}

/// Compara presupuesto vs gasto real del mes, por categoría y total.
final class BudgetEvaluator {
  const new(this.thresholds);

  final TrafficLightThresholds thresholds;

  MonthBudgetStatus evaluate({
    required YearMonth period,
    required List<BudgetLine> lines,
    required List<Transaction> transactions,
  }) {
    final spentByCategory = <String, Money>{};
    for (final t in transactions) {
      if (t.isExpense && period.contains(t.date)) {
        spentByCategory.update(
          t.categoryId,
          (spent) => spent + t.amount,
          ifAbsent: () => t.amount,
        );
      }
    }

    final categories = [
      for (final line in lines.where((l) => l.period == period))
        CategoryBudgetStatus(
          categoryId: line.categoryId,
          status: _status(
            line.limit,
            spentByCategory[line.categoryId] ?? Money.zero,
          ),
        ),
    ];

    return MonthBudgetStatus(
      period: period,
      categories: categories,
      total: _status(
        Money.sum(categories.map((c) => c.status.limit)),
        Money.sum(categories.map((c) => c.status.spent)),
      ),
    );
  }

  BudgetStatus _status(Money limit, Money spent) {
    final usage = Percentage.ratio(spent, limit);
    final light = usage == null
        ? (spent.isPositive ? TrafficLight.critical : TrafficLight.ok)
        : thresholds.classifyUsage(usage);
    return BudgetStatus(limit: limit, spent: spent, usage: usage, light: light);
  }
}
