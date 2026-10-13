import 'package:finance_app/application/advisor/financial_alerts.dart';
import 'package:finance_app/application/advisor/windfall_plan.dart';
import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/application/dashboard/money_overview.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/goal_progress_calculator.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  const food = 'seed-expense-food';
  const housing = 'seed-expense-housing';
  const prima = 'seed-income-prima';
  final today = DateTime(2026, 10, 3, 18);
  final cycle = PayCycle.containing(today, payday: 20);
  final previousCycle = PayCycle.containing(DateTime(2026, 9, 3), payday: 20);
  const settings = FinanceSettings();
  const categories = DefaultCategories.all;

  const rent = FixedMovement(
    id: 'rent',
    name: 'Arriendo',
    kind: TransactionKind.expense,
    amount: Money.pesos(1200000),
    categoryId: housing,
    dayOfMonth: 5,
  );

  (CycleSummary, MoneyOverview) build({
    List<Transaction> current = const [],
    List<Transaction> previous = const [],
    List<FixedMovement> fixed = const [],
  }) {
    final summary = const CycleSummaryBuilder().build(
      cycle: cycle,
      previousCycle: previousCycle,
      today: today,
      cycleTransactions: current,
      previousCycleTransactions: previous,
      categories: categories,
      fixedMovements: fixed,
      settings: settings,
    );
    final overview = const MoneyOverviewBuilder().build(
      summary: summary,
      categories: categories,
      fixedMovements: fixed,
      cycleTransactions: current,
    );
    return (summary, overview);
  }

  List<FinancialAlert> alerts(
    (CycleSummary, MoneyOverview) data, {
    List<Transaction> current = const [],
    List<Transaction> previous = const [],
    List<Debt> debts = const [],
    List<Asset> assets = const [],
    List<GoalProgressItem> goals = const [],
  }) => const FinancialAlertsBuilder().build(
    summary: data.$1,
    overview: data.$2,
    categories: categories,
    cycleTransactions: current,
    previousCycleTransactions: previous,
    debts: debts,
    assets: assets,
    goals: goals,
    settings: settings,
  );

  GoalProgressItem goal(GoalType type, int target, int saved) =>
      GoalProgressItem(
        goal: SavingsGoal(
          id: type.name,
          name: type.name,
          type: type,
          targetAmount: Money.pesos(target),
        ),
        progress: GoalProgress(
          target: Money.pesos(target),
          saved: Money.pesos(saved),
          monthsLeft: null,
          suggestedMonthly: null,
        ),
      );

  final salary = income(1000000, date: DateTime(2026, 9, 20));
  const card = Debt(
    id: 'card',
    name: 'Tarjeta',
    type: DebtType.creditCard,
    originalAmount: Money.pesos(3000000),
    currentBalance: Money.pesos(2000000),
    terms: LoanTerms(
      rate: InterestRate(
        rate: Percentage.whole(30),
        type: InterestRateType.effectiveAnnual,
      ),
      monthlyPayment: Money.pesos(150000),
    ),
  );

  group('dinero libre', () {
    test('libre = disponible − fijos − apartados − ahorro pendiente', () {
      final current = [income(5000000, date: DateTime(2026, 9, 20))];
      final (_, overview) = build(current: current, fixed: [rent]);

      expect(overview.available, const Money.pesos(5000000));
      expect(overview.committed, const Money.pesos(1200000));
      expect(overview.savingsPending, const Money.pesos(500000), reason: '10%');
      expect(overview.free, const Money.pesos(3300000));
      expect(overview.shortfall, isNull);
    });

    test('separa los ingresos extraordinarios', () {
      final current = [salary, income(800000, category: prima, date: today)];
      final (_, overview) = build(current: current);
      expect(overview.extraordinaryIncome, const Money.pesos(800000));
    });
  });

  group('alertas por reglas', () {
    test('falta dinero para un fijo cercano: alerta urgente', () {
      final current = [salary];
      final data = build(current: current, fixed: [rent]);
      final list = alerts(data, current: current);

      expect(list.first.severity, AlertSeverity.critical);
      expect(list.map((a) => a.kind), contains(AlertKind.fixedNotCovered));
      expect(list.map((a) => a.kind), contains(AlertKind.liquidity));
    });

    test('una categoría que sube fuerte frente al ciclo pasado', () {
      final current = [
        income(5000000, date: DateTime(2026, 9, 20)),
        expense(400000, category: food, date: DateTime(2026, 9, 25)),
      ];
      final previous = [
        expense(100000, category: food, date: DateTime(2026, 8, 25)),
      ];
      final data = build(current: current, previous: previous);
      final surge = alerts(
        data,
        current: current,
        previous: previous,
      ).where((a) => a.kind == AlertKind.categorySurge);
      expect(surge.single.title, contains('Alimentación'));
    });

    test('deuda cara, bien que cuesta más de lo que produce y sin fondo', () {
      final data = build(current: [income(5000000, date: today)]);
      final list = alerts(
        data,
        debts: [card],
        assets: [
          Asset(
            id: 'apto',
            name: 'Apartamento',
            type: AssetType.property,
            currentValue: const Money.pesos(200000000),
            valuedAt: today,
            monthlyIncome: const Money.pesos(800000),
            monthlyCost: const Money.pesos(1000000),
          ),
        ],
      );
      final kinds = list.map((a) => a.kind);
      expect(kinds, contains(AlertKind.expensiveDebt));
      expect(kinds, contains(AlertKind.assetDrain));
      expect(kinds, contains(AlertKind.emergencyFund));
    });

    test('meta cumplida: logro (y no pide crear el fondo)', () {
      final data = build(current: [income(5000000, date: today)]);
      final list = alerts(data, goals: [goal(GoalType.emergency, 1000, 1000)]);
      expect(list.map((a) => a.kind), contains(AlertKind.goalReached));
      expect(list.map((a) => a.kind), isNot(contains(AlertKind.emergencyFund)));
    });
  });

  group('reparto de un ingreso extraordinario', () {
    test('prioriza fondo de emergencia y deuda cara; suma lo recibido', () {
      final current = [
        income(5000000, date: DateTime(2026, 9, 20)),
        income(2000000, category: prima, date: today),
      ];
      final (_, overview) = build(current: current);
      final plan = const WindfallPlanner().plan(
        amount: const Money.pesos(2000000),
        overview: overview,
        goals: [goal(GoalType.emergency, 6000000, 1000000)],
        debts: [card],
        essentialMonthly: const Money.pesos(2000000),
        settings: settings,
      );

      final uses = plan.slices.map((s) => s.use).toList();
      expect(uses.first, WindfallUse.emergencyFund);
      expect(uses, contains(WindfallUse.debt));
      expect(uses, contains(WindfallUse.investment));
      expect(
        Money.sum(plan.slices.map((s) => s.amount)),
        const Money.pesos(2000000),
      );
      expect(plan.slices.first.amount, const Money.pesos(1000000));
      expect(plan.slices.first.applicable, isTrue);
    });

    test('si faltaba para los fijos, primero cubre lo pendiente', () {
      final current = [salary, income(1000000, category: prima, date: today)];
      final (_, overview) = build(current: current, fixed: [rent]);
      final plan = const WindfallPlanner().plan(
        amount: const Money.pesos(1000000),
        overview: overview,
        goals: const [],
        debts: const [],
        essentialMonthly: Money.zero,
        settings: settings,
      );

      // Disponible 2M − arriendo 1,2M − ahorro 200 mil = 600 mil libres:
      // 400 mil de la prima taparon lo que faltaba.
      expect(plan.slices.first.use, WindfallUse.obligations);
      expect(plan.slices.first.amount, const Money.pesos(400000));
      expect(
        plan.slices.map((s) => s.use),
        containsAll([WindfallUse.personal, WindfallUse.investment]),
      );
      expect(
        Money.sum(plan.slices.map((s) => s.amount)),
        const Money.pesos(1000000),
      );
    });
  });
}
