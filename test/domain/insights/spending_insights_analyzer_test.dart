import 'package:finance_app/domain/budgets/budget_evaluator.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/insights/insight.dart';
import 'package:finance_app/domain/insights/spending_insights_analyzer.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  const analyzer = SpendingInsightsAnalyzer();
  const savingCategories = {'investments'};
  final september = DateTime(2026, 9, 10);

  // Octubre: 1.000.000 en total. Comida = 12 compras pequeñas de 20.000.
  final current = <Transaction>[
    for (var i = 0; i < 12; i++) expense(20000),
    expense(135000, category: 'entertainment'),
    expense(625000, category: 'transport'),
    expense(500000, category: 'investments'),
  ];
  // Septiembre: 1.000.000 en total.
  final previous = <Transaction>[
    expense(250000, date: september),
    expense(100000, category: 'entertainment', date: september),
    expense(600000, category: 'transport', date: september),
    expense(50000, category: 'gifts', date: september),
  ];

  List<Insight> analyze({MonthBudgetStatus? budget}) => analyzer.analyze(
    current: current,
    previous: previous,
    savingCategoryIds: savingCategories,
    smallExpenseThreshold: const Money.pesos(20000),
    budget: budget,
  );

  test('breakdown excluye ahorro y ordena por monto', () {
    final breakdown = analyzer.breakdown(
      current,
      savingCategoryIds: savingCategories,
    );
    expect(breakdown.map((c) => c.categoryId), [
      'transport',
      'food',
      'entertainment',
    ]);
    expect(breakdown[1].share, const Percentage.whole(24));
    expect(breakdown[1].count, 12);
  });

  test('reporta participación de las categorías principales', () {
    final shares = analyze().whereType<CategoryShareInsight>().toList();
    expect(shares, hasLength(3));
    expect(shares.first.categoryId, 'transport');
    expect(shares.first.share, const Percentage.basisPoints(6250));
  });

  test('reporta variaciones significativas, también desapariciones', () {
    final variations = {
      for (final v in analyze().whereType<CategoryVariationInsight>())
        v.categoryId: v.change,
    };
    expect(variations, {
      'gifts': const Percentage.whole(-100),
      'entertainment': const Percentage.whole(35),
    });
  });

  test('sin variación total significativa no se reporta', () {
    expect(analyze().whereType<TotalSpendingVariationInsight>(), isEmpty);
  });

  test('cuenta y suma las compras pequeñas', () {
    final small = analyze().whereType<SmallExpensesInsight>().single;
    expect(small.count, 12);
    expect(small.total, const Money.pesos(240000));
  });

  test('incluye el uso del presupuesto cuando existe', () {
    const october = YearMonth(2026, 10);
    final budget = const BudgetEvaluator(TrafficLightThresholds()).evaluate(
      period: october,
      lines: const [
        BudgetLine(
          id: 'b1',
          period: october,
          categoryId: 'transport',
          limit: Money.pesos(680000),
        ),
      ],
      transactions: current,
    );
    final usage = analyze(budget: budget).whereType<BudgetUsageInsight>();
    expect(usage.single.usage, const Percentage.basisPoints(9191));
    expect(usage.single.light, TrafficLight.warning);
  });
}
