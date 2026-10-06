import 'package:finance_app/domain/insights/cash_flow_calculator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  const calculator = CashFlowCalculator();
  const savingCategories = {'investments'};

  test('ahorro = ingresos − gastos reales (excluye categorías de ahorro)', () {
    final flow = calculator.calculate([
      income(7000000),
      expense(1000000),
      expense(500000, category: 'transport'),
      expense(700000, category: 'investments'),
    ], savingCategoryIds: savingCategories);

    expect(flow.income, const Money.pesos(7000000));
    expect(flow.expenses, const Money.pesos(1500000));
    expect(flow.savingContributions, const Money.pesos(700000));
    expect(flow.savings, const Money.pesos(5500000));
    expect(flow.savingsRate, const Percentage.basisPoints(7857));
    expect(flow.expenseRatio, const Percentage.basisPoints(2143));
  });

  test('sin ingresos las tasas no se pueden calcular', () {
    final flow = calculator.calculate([
      expense(1000),
    ], savingCategoryIds: savingCategories);
    expect(flow.savings, const Money.pesos(-1000));
    expect(flow.savingsRate, isNull);
    expect(flow.expenseRatio, isNull);
  });
}
