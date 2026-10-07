import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  const food = 'seed-expense-food';
  const transport = 'seed-expense-transport';
  const investments = 'seed-expense-investments';
  final today = DateTime(2026, 10, 3, 18);
  final cycle = PayCycle.containing(today, payday: 20);

  CycleSummary build({
    List<Transaction> current = const [],
    List<Transaction> previous = const [],
    List<FixedMovement> fixed = const [],
    List<BudgetLine> budgets = const [],
    List<Provision> provisions = const [],
  }) => const CycleSummaryBuilder().build(
    cycle: cycle,
    today: today,
    cycleTransactions: current,
    previousCycleTransactions: previous,
    categories: DefaultCategories.all,
    fixedMovements: fixed,
    settings: const FinanceSettings(),
    budgetLines: budgets,
    provisions: provisions,
    provisionTransactions: current.where((t) => t.provisionId != null).toList(),
  );

  test('lo que queda = ingresos − todo lo que salió del ciclo', () {
    final summary = build(
      current: [
        income(5000000, date: DateTime(2026, 9, 20)),
        expense(300000, category: food),
        expense(100000, category: transport),
        expense(600000, category: investments),
      ],
    );

    expect(summary.income, const Money.pesos(5000000));
    expect(summary.outflow, const Money.pesos(1000000));
    expect(summary.left, const Money.pesos(4000000));
    expect(summary.spentShare, const Percentage.whole(20));
    expect(summary.usageLight, TrafficLight.ok);
    expect(summary.daysLeft, 17);
  });

  test('desglosa por categoría de mayor a menor con su %', () {
    final summary = build(
      current: [
        expense(100000, category: transport),
        expense(200000, category: food),
        expense(100000, category: food),
      ],
    );

    expect(summary.expenseTotals.map((t) => t.category?.id), [food, transport]);
    expect(summary.expenseTotals.first.share, const Percentage.whole(75));
    expect(summary.expenseTotals.first.count, 2);
    expect(summary.incomeTotals, isEmpty);
  });

  test('descuenta los fijos pendientes y reparte por día', () {
    final summary = build(
      current: [income(5000000, date: DateTime(2026, 9, 20))],
      fixed: const [
        FixedMovement(
          id: 'colegio',
          name: 'Colegio',
          kind: TransactionKind.expense,
          amount: Money.pesos(400000),
          categoryId: 'seed-expense-education',
          dayOfMonth: 10,
        ),
      ],
    );

    expect(summary.leftAfterFixed, const Money.pesos(4600000));
    expect(summary.dailyAllowance, const Money.pesos(4600000).divide(17));
  });

  test('compara con lo que quedó el ciclo anterior', () {
    final summary = build(
      current: [income(5000000), expense(1000000)],
      previous: [
        income(5000000, date: DateTime(2026, 8, 25)),
        expense(4500000, date: DateTime(2026, 9)),
      ],
    );

    expect(summary.previousLeft, const Money.pesos(500000));
    expect(summary.leftVsPrevious, const Money.pesos(3500000));
    expect(build().previousLeft, isNull);
  });

  test('tope diario: aparta fijos, mercado presupuestado y ahorro; ignora '
      'el mercado del día', () {
    final groceries = DefaultCategories.groceries.id;
    final summary = build(
      current: [
        income(
          4000000,
          category: DefaultCategories.salaryId,
          date: cycle.start,
        ),
        expense(200000, category: groceries, date: DateTime(2026, 10)),
        expense(30000, category: food, date: today),
        expense(50000, category: groceries, date: today),
      ],
      fixed: [
        const FixedMovement(
          id: 'rent',
          name: 'Arriendo',
          kind: TransactionKind.expense,
          amount: Money.pesos(1000000),
          categoryId: 'seed-expense-housing',
          dayOfMonth: 5,
        ),
      ],
      budgets: [
        BudgetLine(
          id: 'b1',
          period: YearMonth.fromDate(today),
          categoryId: groceries,
          limit: const Money.pesos(600000),
        ),
      ],
    );

    final cap = summary.dailyCap!;
    // Libre: 4.000.000 − 280.000 gastado − 1.000.000 arriendo + 30.000 de
    // hoy − 350.000 de mercado por gastar − 400.000 de ahorro (10%).
    expect(cap.reserved, const Money.pesos(750000));
    expect(cap.cap, const Money.pesos(2000000).divide(17));
    expect(cap.spentToday, const Money.pesos(30000), reason: 'sin mercado');
  });

  test('los pagos del año se apartan del tope diario y lo apartado no '
      'cuenta como meta de ahorro', () {
    final soat = Provision(
      id: 'soat',
      name: 'SOAT',
      amount: const Money.pesos(340000),
      everyMonths: 12,
      nextDue: DateTime(2026, 11),
      categoryId: transport,
    );
    final salary = income(3400000, date: DateTime(2026, 9, 20));
    final without = build(current: [salary]).dailyCap!;
    final deposit = Transaction(
      id: 'dep',
      kind: TransactionKind.expense,
      amount: const Money.pesos(70000),
      categoryId: DefaultCategories.provisions.id,
      date: DateTime(2026, 10),
      createdAt: DateTime(2026, 10),
      provisionId: 'soat',
    );

    final pending = build(current: [salary], provisions: [soat]);
    // 2 sueldos antes del 1 nov: 170.000 por ciclo.
    expect(pending.provisionPlan.pendingThisCycle, const Money.pesos(170000));
    expect(
      pending.dailyCap!.reserved,
      without.reserved + const Money.pesos(170000),
    );

    final partly = build(current: [salary, deposit], provisions: [soat]);
    expect(partly.provisionPlan.pendingThisCycle, const Money.pesos(100000));
    // La meta de ahorro (10%) sigue completa: el apartado no la cubre.
    expect(
      partly.dailyCap!.reserved,
      without.reserved + const Money.pesos(100000),
    );
  });
}
