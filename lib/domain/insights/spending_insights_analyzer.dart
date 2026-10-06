import 'package:finance_app/domain/budgets/budget_evaluator.dart';
import 'package:finance_app/domain/insights/insight.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

final class CategorySpending {
  const new({
    required this.categoryId,
    required this.amount,
    required this.count,
    required this.share,
  });

  final String categoryId;
  final Money amount;
  final int count;

  /// Participación sobre el gasto total del período.
  final Percentage share;
}

/// Detecta patrones de gasto ("fugas de dinero") comparando períodos.
final class SpendingInsightsAnalyzer {
  const new({
    this.significantVariation = defaultSignificantVariation,
    this.minSmallExpenses = defaultMinSmallExpenses,
    this.topCategories = defaultTopCategories,
  });

  static const defaultSignificantVariation = Percentage.whole(20);
  static const defaultMinSmallExpenses = 5;
  static const defaultTopCategories = 3;

  /// Variación mínima (en valor absoluto) para reportar un cambio.
  final Percentage significantVariation;

  /// Cantidad mínima de compras pequeñas para reportarlas.
  final int minSmallExpenses;
  final int topCategories;

  /// Gasto real por categoría, de mayor a menor.
  List<CategorySpending> breakdown(
    List<Transaction> transactions, {
    required Set<String> savingCategoryIds,
  }) {
    final expenses = _realExpenses(transactions, savingCategoryIds);
    final total = Money.sum(expenses.map((t) => t.amount));
    final amounts = <String, Money>{};
    final counts = <String, int>{};
    for (final t in expenses) {
      amounts.update(
        t.categoryId,
        (a) => a + t.amount,
        ifAbsent: () => t.amount,
      );
      counts.update(t.categoryId, (c) => c + 1, ifAbsent: () => 1);
    }
    return [
      for (final MapEntry(key: id, value: amount) in amounts.entries)
        CategorySpending(
          categoryId: id,
          amount: amount,
          count: counts[id]!,
          share: Percentage.ratio(amount, total) ?? Percentage.zero,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<Insight> analyze({
    required List<Transaction> current,
    required List<Transaction> previous,
    required Set<String> savingCategoryIds,
    required Money smallExpenseThreshold,
    MonthBudgetStatus? budget,
  }) {
    final currentBreakdown = breakdown(
      current,
      savingCategoryIds: savingCategoryIds,
    );
    final previousBreakdown = breakdown(
      previous,
      savingCategoryIds: savingCategoryIds,
    );

    return [
      if (budget != null && budget.hasBudget && budget.total.usage != null)
        BudgetUsageInsight(
          usage: budget.total.usage!,
          light: budget.total.light,
        ),
      ?_totalVariation(currentBreakdown, previousBreakdown),
      for (final c in currentBreakdown.take(topCategories))
        CategoryShareInsight(
          categoryId: c.categoryId,
          amount: c.amount,
          share: c.share,
        ),
      ..._categoryVariations(currentBreakdown, previousBreakdown),
      ?_smallExpenses(current, savingCategoryIds, smallExpenseThreshold),
    ];
  }

  List<Transaction> _realExpenses(
    List<Transaction> transactions,
    Set<String> savingCategoryIds,
  ) => transactions
      .where((t) => t.isExpense && !savingCategoryIds.contains(t.categoryId))
      .toList();

  TotalSpendingVariationInsight? _totalVariation(
    List<CategorySpending> current,
    List<CategorySpending> previous,
  ) {
    final currentTotal = Money.sum(current.map((c) => c.amount));
    final previousTotal = Money.sum(previous.map((c) => c.amount));
    final change = _change(currentTotal, previousTotal);
    if (change == null || change.abs < significantVariation) return null;
    return TotalSpendingVariationInsight(
      current: currentTotal,
      previous: previousTotal,
      change: change,
    );
  }

  List<CategoryVariationInsight> _categoryVariations(
    List<CategorySpending> current,
    List<CategorySpending> previous,
  ) {
    final previousById = {for (final p in previous) p.categoryId: p.amount};
    final currentById = {for (final c in current) c.categoryId: c.amount};
    final ids = {...previousById.keys, ...currentById.keys};
    return [
      for (final id in ids)
        if (_change(
              currentById[id] ?? Money.zero,
              previousById[id] ?? Money.zero,
            )
            case final change? when change.abs >= significantVariation)
          CategoryVariationInsight(
            categoryId: id,
            current: currentById[id] ?? Money.zero,
            previous: previousById[id] ?? Money.zero,
            change: change,
          ),
    ]..sort((a, b) => b.change.abs.compareTo(a.change.abs));
  }

  SmallExpensesInsight? _smallExpenses(
    List<Transaction> transactions,
    Set<String> savingCategoryIds,
    Money threshold,
  ) {
    final small = _realExpenses(
      transactions,
      savingCategoryIds,
    ).where((t) => t.amount <= threshold).toList();
    if (small.length < minSmallExpenses) return null;
    return SmallExpensesInsight(
      count: small.length,
      total: Money.sum(small.map((t) => t.amount)),
      threshold: threshold,
    );
  }

  /// Variación relativa. `null` si no hay base de comparación.
  Percentage? _change(Money current, Money previous) =>
      Percentage.ratio(current - previous, previous);
}
