import 'package:finance_app/application/budgets/budget_use_cases.dart';
import 'package:finance_app/application/debts/debt_use_cases.dart';
import 'package:finance_app/application/savings/savings_use_cases.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/drift_budget_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_debt_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_savings_goal_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_settings_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late FixedClock clock;
  late SequentialIds ids;

  setUp(() {
    db = createTestDatabase();
    clock = FixedClock(DateTime(2026, 10, 2));
    ids = SequentialIds();
  });

  T okValue<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Falló: ${failure.message}'),
  };

  group('pagos de deudas', () {
    late DriftDebtRepository debts;
    late DriftTransactionRepository transactions;

    const loan = Debt(
      id: 'd1',
      name: 'Crédito',
      type: DebtType.bankLoan,
      originalAmount: Money.pesos(1000000),
      currentBalance: Money.pesos(100000),
      terms: LoanTerms(
        rate: InterestRate(
          rate: Percentage.whole(1),
          type: InterestRateType.effectiveMonthly,
        ),
        monthlyPayment: Money.pesos(50000),
        monthlyFees: Money.pesos(10000),
        totalInstallments: 24,
        paidInstallments: 20,
      ),
    );

    setUp(() async {
      debts = DriftDebtRepository(db);
      transactions = DriftTransactionRepository(db);
      await debts.save(loan);
    });

    test('la cuota baja solo el capital y queda como gasto', () async {
      final updated = okValue(
        await RegisterDebtPayment(
          debts: debts,
          transactions: transactions,
          clock: clock,
          ids: ids,
        ).call(debt: loan, amount: const Money.pesos(50000)),
      );

      // 50.000 − 10.000 de seguro − 1.000 de interés = 39.000 a capital.
      expect(updated.currentBalance, const Money.pesos(61000));
      expect(updated.terms!.paidInstallments, 21);
      expect(await debts.getById('d1'), updated);

      final payment = (await transactions.getRecent(limit: 1)).single;
      expect(payment.amount, const Money.pesos(50000));
      expect(payment.categoryId, DefaultCategories.debtsId);
      expect(payment.debtId, 'd1');
    });

    test('el abono extra va completo a capital y no excede el saldo', () async {
      final updated = okValue(
        await RegisterExtraPayment(
          debts: debts,
          transactions: transactions,
          clock: clock,
          ids: ids,
        ).call(debt: loan, amount: const Money.pesos(150000)),
      );

      expect(updated.currentBalance, Money.zero);
      expect(updated.isPaidOff, isTrue);
      expect(updated.terms!.paidInstallments, 20);
      final extra = await debts.getExtraPayments('d1');
      expect(extra.single.amount, const Money.pesos(100000));
    });
  });

  group('presupuesto', () {
    test('copia el mes anterior solo si el mes está vacío', () async {
      final budgets = DriftBudgetRepository(db);
      const october = YearMonth(2026, 10);
      await budgets.save(
        BudgetLine(
          id: 'b1',
          period: october.previous,
          categoryId: 'seed-expense-food',
          limit: const Money.pesos(500000),
        ),
      );
      final copy = CopyPreviousMonthBudget(budgets: budgets, ids: ids);

      expect(okValue(await copy(october)), 1);
      expect(okValue(await copy(october)), 0);
      expect(
        (await budgets.getByMonth(october)).single.limit,
        const Money.pesos(500000),
      );
    });

    test('rechaza límites en cero', () async {
      final result =
          await SetBudgetLimit(
            budgets: DriftBudgetRepository(db),
            ids: ids,
          ).call(
            period: const YearMonth(2026, 10),
            categoryId: 'seed-expense-food',
            limit: Money.zero,
          );
      expect(result, isA<Err<void>>());
    });
  });

  group('ahorro', () {
    test('la regla de ahorro es configurable entre 1% y 100%', () async {
      final update = UpdateSavingsTarget(DriftSettingsRepository(db));

      final updated = okValue(await update(const Percentage.whole(15)));
      expect(updated.savingsTargetRate, const Percentage.whole(15));

      final invalid = await update(Percentage.zero);
      expect(
        invalid,
        isA<Err<Object?>>().having(
          (e) => e.failure,
          'failure',
          isA<ValidationFailure>(),
        ),
      );
    });

    test('el fondo de emergencia calcula su objetivo', () async {
      final goal = okValue(
        await SaveGoal(goals: DriftSavingsGoalRepository(db), ids: ids).call(
          name: 'Fondo de emergencia',
          type: GoalType.emergency,
          targetAmount: Money.zero,
          emergencyPlan: const EmergencyPlan(
            essentialMonthlyExpenses: Money.pesos(2500000),
            targetMonths: 3,
          ),
        ),
      );
      expect(goal.targetAmount, const Money.pesos(7500000));
    });

    test('retiros negativos se permiten; aportes en cero no', () async {
      final goals = DriftSavingsGoalRepository(db);
      final add = AddContribution(goals: goals, clock: clock, ids: ids);
      await goals.save(
        const SavingsGoal(
          id: 'g1',
          name: 'Viaje',
          type: GoalType.travel,
          targetAmount: Money.pesos(1000000),
        ),
      );

      expect(
        await add(goalId: 'g1', amount: const Money.pesos(300000)),
        isA<Ok<void>>(),
      );
      expect(
        await add(goalId: 'g1', amount: const Money.pesos(-100000)),
        isA<Ok<void>>(),
      );
      expect(await add(goalId: 'g1', amount: Money.zero), isA<Err<void>>());
      expect(
        Money.sum((await goals.getContributions()).map((c) => c.amount)),
        const Money.pesos(200000),
      );
    });
  });
}
