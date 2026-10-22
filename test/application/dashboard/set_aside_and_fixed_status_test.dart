import 'package:finance_app/application/advisor/windfall_plan.dart';
import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/application/dashboard/money_overview.dart';
import 'package:finance_app/application/dashboard/set_aside_plan.dart';
import 'package:finance_app/application/fixed/fixed_cycle_status.dart';
import 'package:finance_app/application/provisions/provision_use_cases.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_coverage.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/goal_progress_calculator.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/repositories/drift_debt_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_savings_goal_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';
import '../../support/test_database.dart';

void main() {
  const housing = 'seed-expense-housing';
  const groceries = 'seed-expense-groceries';
  final today = DateTime(2026, 10, 3, 18);
  final cycle = PayCycle.containing(today, payday: 20);
  final salary = income(
    5000000,
    category: DefaultCategories.salaryId,
    date: DateTime(2026, 9, 20),
  );

  FixedMovement fixed(String id, int day, {bool expense = true}) =>
      FixedMovement(
        id: id,
        name: id,
        kind: expense ? TransactionKind.expense : TransactionKind.income,
        amount: const Money.pesos(500000),
        categoryId: expense ? housing : DefaultCategories.salaryId,
        dayOfMonth: day,
        autoDebit: true,
      );

  final soat = Provision(
    id: 'soat',
    name: 'SOAT',
    amount: const Money.pesos(1200000),
    everyMonths: 12,
    nextDue: DateTime(2027, 3),
    categoryId: 'seed-expense-transport',
  );

  (CycleSummary, MoneyOverview) build({
    List<Transaction> current = const [],
    List<FixedMovement> movements = const [],
    List<BudgetLine> budget = const [],
    List<Provision> provisions = const [],
  }) {
    final summary = const CycleSummaryBuilder().build(
      cycle: cycle,
      today: today,
      cycleTransactions: current,
      previousCycleTransactions: const [],
      categories: DefaultCategories.all,
      fixedMovements: movements,
      settings: const FinanceSettings(),
      budgetLines: budget,
      provisions: provisions,
    );
    return (
      summary,
      const MoneyOverviewBuilder().build(
        summary: summary,
        categories: DefaultCategories.all,
        fixedMovements: movements,
        cycleTransactions: current,
      ),
    );
  }

  group('fijos del ciclo por estado', () {
    test('pagado (ya pasó) va aparte de lo que falta pagar', () {
      final movements = [
        fixed('arriendo', 1),
        fixed('gym', 15),
        fixed('sueldo', 20, expense: false),
      ];
      final paid = Transaction(
        id: 'p1',
        kind: TransactionKind.expense,
        amount: const Money.pesos(500000),
        categoryId: housing,
        date: DateTime(2026, 10),
        createdAt: DateTime(2026, 10),
        fixedMovementId: 'arriendo',
      );
      final current = [salary, paid];
      final (summary, overview) = build(current: current, movements: movements);

      final statuses = const FixedCycleStatusBuilder().build(
        movements: movements,
        schedule: summary.upcomingFixed,
        coverage: overview.coverage,
        cycleTransactions: current,
      );
      final byId = {for (final s in statuses) s.movement.id: s};

      expect(byId['arriendo']!.state, FixedCycleState.paid);
      expect(byId['arriendo']!.date, DateTime(2026, 10));
      expect(byId['gym']!.state, FixedCycleState.upcoming);
      expect(byId['gym']!.coverage, ObligationState.covered);
      expect(byId['sueldo']!.state, FixedCycleState.received);
      expect(statuses.first.movement.id, 'gym', reason: 'lo pendiente arriba');
    });
  });

  group('libre para gastar y tope del día cuentan lo mismo', () {
    test('el presupuesto del mes por gastar se protege en ambos', () {
      final budget = [
        BudgetLine(
          id: 'b1',
          categoryId: groceries,
          period: YearMonth.fromDate(today),
          limit: const Money.pesos(800000),
        ),
      ];
      final (summary, overview) = build(current: [salary], budget: budget);

      expect(overview.plannedPending, const Money.pesos(800000));
      // 5M − 10% ahorro − 800 mil de mercado.
      expect(overview.free, const Money.pesos(3700000));
      final cap = summary.dailyCap!;
      expect(
        cap.cap.times(summary.daysLeft) + cap.surplus,
        overview.free,
        reason: 'el tope (y lo que sobra) sale del mismo dinero libre',
      );
      expect(overview.dayToDaySurplus, cap.surplus);
    });

    test('lo ya apartado para pagos del año se ve en Inicio', () {
      final deposit = Transaction(
        id: 'd1',
        kind: TransactionKind.expense,
        amount: const Money.pesos(100000),
        categoryId: DefaultCategories.provisions.id,
        date: DateTime(2026, 9, 21),
        createdAt: DateTime(2026, 9, 21),
        provisionId: 'soat',
      );
      final summary = const CycleSummaryBuilder().build(
        cycle: cycle,
        today: today,
        cycleTransactions: [salary, deposit],
        previousCycleTransactions: const [],
        categories: DefaultCategories.all,
        fixedMovements: const [],
        settings: const FinanceSettings(),
        provisions: [soat],
        provisionTransactions: [deposit],
      );
      final overview = const MoneyOverviewBuilder().build(
        summary: summary,
        categories: DefaultCategories.all,
        fixedMovements: const [],
        cycleTransactions: [salary, deposit],
      );
      expect(overview.provisionsSaved, const Money.pesos(100000));
      expect(overview.provisionsPending.isPositive, isTrue);
      expect(overview.provisionsToday, isNotNull);
    });
  });

  group('apartar lo que sobra', () {
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

    test('primero pagos del año, luego el fondo; deja la mitad libre', () {
      final (summary, overview) = build(current: [salary], provisions: [soat]);
      final plan = const SetAsidePlanner().plan(
        overview: overview,
        provisions: summary.provisionPlan,
        goals: [
          goal(GoalType.custom, 50000000, 0),
          goal(GoalType.emergency, 50000000, 0),
        ],
      );

      expect(plan.targets.first.provision?.id, 'soat');
      expect(plan.targets[1].goal?.type, GoalType.emergency);
      final toGoals = Money.sum(
        plan.targets.where((t) => t.goal != null).map((t) => t.suggested),
      );
      expect(
        toGoals,
        overview.free.applyPercentage(SetAsidePlanner.freeShareForGoals),
      );
    });

    test('aplicar aparta al pago del año y aporta a la meta', () async {
      final db = createTestDatabase();
      final transactions = DriftTransactionRepository(db);
      final goals = DriftSavingsGoalRepository(db);
      final clock = FixedClock(today);
      final ids = SequentialIds();
      final emergency = goal(GoalType.emergency, 1000000, 0);
      await goals.save(emergency.goal);
      final apply = ApplySetAside(
        provisions: SetAsideForProvision(
          transactions: transactions,
          clock: clock,
          ids: ids,
        ),
        goals: ApplyWindfallSlices(
          goals: goals,
          debts: DriftDebtRepository(db),
          transactions: transactions,
          clock: clock,
          ids: ids,
        ),
      );

      final result = await apply([
        (
          SetAsideTarget(
            name: 'SOAT',
            suggested: const Money.pesos(100000),
            remaining: const Money.pesos(1200000),
            reason: '',
            provision: soat,
          ),
          const Money.pesos(100000),
        ),
        (
          SetAsideTarget(
            name: 'Fondo',
            suggested: const Money.pesos(200000),
            remaining: const Money.pesos(1000000),
            reason: '',
            goal: emergency.goal,
          ),
          const Money.pesos(200000),
        ),
      ]);

      expect(result.isOk, isTrue);
      final saved = await transactions.getRecent(limit: 10);
      expect(
        saved.map((t) => t.categoryId),
        containsAll([
          DefaultCategories.provisions.id,
          DefaultCategories.investmentsId,
        ]),
      );
      expect(
        (await goals.getContributions()).single.amount,
        const Money.pesos(200000),
      );
    });
  });
}
