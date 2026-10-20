import 'package:finance_app/application/cashflow/cashflow_statement.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle_resolver.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  final today = DateTime(2026, 10, 13);
  const investments = 'seed-expense-investments';
  const prima = 'seed-income-prima';

  CashflowStatement build(List<Transaction> transactions, List<Asset> assets) =>
      const CashflowStatementBuilder().build(
        resolver: PayCycleResolver.fromTransactions(
          payday: 20,
          transactions: transactions,
        ),
        today: today,
        transactions: transactions,
        savingCategoryIds: {
          for (final c in DefaultCategories.all)
            if (c.countsAsSaving) c.id,
        },
        extraordinaryCategoryIds: {prima},
        assets: assets,
        debts: const [],
        investments: const [],
        monthlyFixedExpenses: const Money.pesos(1800000),
      );

  final assets = [
    Asset(
      id: 'local',
      name: 'Local',
      type: AssetType.property,
      currentValue: const Money.pesos(80000000),
      valuedAt: today,
      monthlyIncome: const Money.pesos(500000),
    ),
    Asset(
      id: 'carro',
      name: 'Carro',
      type: AssetType.vehicle,
      currentValue: const Money.pesos(40000000),
      valuedAt: today,
      monthlyCost: const Money.pesos(300000),
    ),
  ];

  // Ciclo cerrado: 20 ago – 19 sep. El actual empieza el 20 sep.
  final transactions = [
    income(
      3000000,
      category: DefaultCategories.salaryId,
      date: DateTime(2026, 8, 20),
    ),
    expense(
      2000000,
      category: 'seed-expense-food',
      date: DateTime(2026, 8, 25),
    ),
    expense(300000, category: investments, date: DateTime(2026, 8, 26)),
    income(1000000, category: prima, date: DateTime(2026, 8, 30)),
    // El arriendo del local registrado como ingreso: ya es el pasivo.
    income(
      500000,
      category: 'seed-income-additional',
      date: DateTime(2026, 9, 2),
    ),
    income(
      3000000,
      category: DefaultCategories.salaryId,
      date: DateTime(2026, 9, 20),
    ),
  ];

  test('estado de resultados con el ciclo cerrado: sin ahorro, sin prima y '
      'sin contar dos veces el arriendo', () {
    final s = build(transactions, assets);

    expect(s.cyclesUsed, 1);
    expect(s.salary, const Money.pesos(3000000));
    expect(s.otherIncome, Money.zero);
    expect(s.passiveIncome, const Money.pesos(500000));
    expect(s.expenses, const Money.pesos(2000000));
    expect(s.cashflow, const Money.pesos(1500000));
    expect(s.freedom!.value, 25);
    expect(s.passiveGap, const Money.pesos(1500000));
    expect(s.outOfRatRace, isFalse);
    expect(s.incomeAssets.single.name, 'Local');
    expect(s.costlyAssets.single.monthly, const Money.pesos(-300000));
  });

  test('una oportunidad sube el flujo y dice en cuánto se recupera', () {
    final outcome = build(transactions, assets).play(
      const CashflowCard(
        kind: CashflowCardKind.opportunity,
        upfront: Money.pesos(10000000),
        monthlyIncome: Money.pesos(1000000),
        monthlyCost: Money.pesos(200000),
      ),
    );

    expect(outcome.cashflowChange, const Money.pesos(800000));
    expect(outcome.after.freedom!.value, closeTo(68.18, 0.01));
    expect(outcome.paybackMonths, 13);
    expect(outcome.monthsOfCashflow, 7);
  });

  test('un capricho a cuotas baja el flujo y no se recupera', () {
    final outcome = build(transactions, assets).play(
      const CashflowCard(
        kind: CashflowCardKind.doodad,
        monthlyCost: Money.pesos(250000),
      ),
    );

    expect(outcome.cashflowChange, const Money.pesos(-250000));
    expect(outcome.paybackMonths, isNull);
  });

  test('sin ciclos cerrados estima con los fijos', () {
    final s = build([transactions.last], const []);
    expect(s.isEstimate, isTrue);
    expect(s.expenses, const Money.pesos(1800000));
    expect(s.salary, const Money.pesos(3000000));
  });
}
