import 'package:finance_app/domain/budgets/budget_evaluator.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  const october = YearMonth(2026, 10);
  const evaluator = BudgetEvaluator(TrafficLightThresholds());

  BudgetLine line(String category, int pesos) => BudgetLine(
    id: 'b-$category',
    period: october,
    categoryId: category,
    limit: Money.pesos(pesos),
  );

  final status = evaluator.evaluate(
    period: october,
    lines: [line('food', 500000), line('transport', 300000)],
    transactions: [
      expense(300000),
      expense(150000),
      expense(350000, category: 'transport'),
      expense(100000, category: 'entertainment'),
      expense(100000, date: DateTime(2026, 9, 30)),
      income(7000000),
    ],
  );

  CategoryBudgetStatus byCategory(String id) =>
      status.categories.firstWhere((c) => c.categoryId == id);

  test('calcula gastado, disponible y uso por categoría', () {
    final food = byCategory('food').status;
    expect(food.spent, const Money.pesos(450000));
    expect(food.available, const Money.pesos(50000));
    expect(food.usage, const Percentage.whole(90));
    expect(food.light, TrafficLight.warning);
  });

  test('detecta categorías que superan el presupuesto', () {
    final transport = byCategory('transport').status;
    expect(transport.isOverBudget, isTrue);
    expect(transport.available, const Money.pesos(-50000));
    expect(transport.light, TrafficLight.critical);
    expect(status.overBudget.map((c) => c.categoryId), ['transport']);
  });

  test('el total solo suma categorías presupuestadas del mes', () {
    expect(status.total.limit, const Money.pesos(800000));
    expect(status.total.spent, const Money.pesos(800000));
    expect(status.total.usage, Percentage.hundred);
  });

  test('límite cero: rojo solo si hubo gasto', () {
    final result = evaluator.evaluate(
      period: october,
      lines: [line('food', 0), line('transport', 0)],
      transactions: [expense(1000)],
    );
    expect(result.categories.first.status.usage, isNull);
    expect(result.categories.first.status.light, TrafficLight.critical);
    expect(result.categories.last.status.light, TrafficLight.ok);
  });
}
