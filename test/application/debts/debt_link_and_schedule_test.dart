import 'package:finance_app/application/cycles/load_current_cycle.dart';
import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/debts/debt_overview.dart';
import 'package:finance_app/application/fixed/fixed_movement_use_cases.dart';
import 'package:finance_app/application/reminders/reminder_planner.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_projector.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/repositories/drift_debt_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_fixed_movement_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_settings_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_database.dart';

void main() {
  Debt loan({int paid = 5, int total = 24, int rate = 24}) => Debt(
    id: 'carro',
    name: 'Carro',
    type: DebtType.bankLoan,
    originalAmount: const Money.pesos(20000000),
    currentBalance: const Money.pesos(15000000),
    terms: LoanTerms(
      rate: InterestRate(
        rate: Percentage.whole(rate),
        type: InterestRateType.effectiveAnnual,
      ),
      monthlyPayment: const Money.pesos(1000000),
      monthlyFees: const Money.pesos(50000),
      totalInstallments: total,
      paidInstallments: paid,
    ),
  );

  group('cuotas: cálculo frente a tu registro', () {
    test('explica la diferencia con la tasa que haría cuadrar', () {
      // 15 M a 24% EA con 950 mil a capital+interés: ~18 cuotas; el
      // registro dice 19.
      final overview = DebtOverview.build(
        debt: loan(),
        currentMonth: const YearMonth(2026, 10),
      );
      final projection = overview.projection!;
      final recorded = overview.recorded!;
      expect(recorded.months, 19);
      expect(recorded.totalToPay, const Money.pesos(19000000));
      expect(recorded.fees, const Money.pesos(950000));
      expect(recorded.interest, const Money.pesos(3050000));
      expect(overview.scheduleMismatch, projection.months != 19);
      expect(
        overview.projectedTotal,
        loan().currentBalance + projection.totalInterest + projection.totalFees,
      );
      // Con 19 cuotas, la tasa que cuadra es más alta que la anotada.
      expect(recorded.impliedAnnualRate, greaterThan(0.24));
    });

    test('tasa implícita: con la tasa real vuelve al mismo número', () {
      const projector = LoanProjector();
      final monthly = projector.impliedMonthlyRate(
        balance: const Money.pesos(10000000),
        payment: const Money.pesos(500000),
        months: 24,
      )!;
      final installment = monthly * 1000000000 / (1 - _pow(1 + monthly, -24));
      expect(installment, closeTo(50000000, 1));
      expect(
        projector.impliedMonthlyRate(
          balance: const Money.pesos(10000000),
          payment: const Money.pesos(400000),
          months: 24,
        ),
        isNull,
        reason: 'cuota × meses no alcanza el saldo: no hay interés',
      );
    });
  });

  group('crédito enlazado a un gasto fijo', () {
    test('al registrarse la cuota baja el saldo y suma la cuota', () async {
      final db = createTestDatabase();
      final fixed = DriftFixedMovementRepository(db);
      final debts = DriftDebtRepository(db);
      final transactions = DriftTransactionRepository(db);
      final clock = FixedClock(DateTime(2026, 10, 12, 9));
      final ids = SequentialIds();
      final cycle = LoadCurrentCycle(
        settings: DriftSettingsRepository(db),
        transactions: transactions,
      );
      final save = SaveFixedMovement(
        fixed: fixed,
        currentCycle: cycle,
        clock: clock,
        ids: ids,
      );
      await debts.save(loan());

      final link = LinkDebtToFixed(fixed: fixed, save: save);
      final created = await link(debt: loan(), dayOfMonth: 15);
      final movement = (created as Ok<FixedMovement>).value;
      expect(movement.debtId, 'carro');
      expect(movement.amount, const Money.pesos(1000000));
      expect(movement.categoryId, DefaultCategories.debtsId);

      // Llega el 15 y el usuario toca "Ya lo pagué": paga el crédito.
      final confirm = ConfirmVariableFixed(
        fixed: fixed,
        transactions: transactions,
        debts: debts,
        clock: FixedClock(DateTime(2026, 10, 15, 9)),
        ids: ids,
      );
      expect(
        await confirm(
          movement: movement,
          scheduledDate: DateTime(2026, 10, 15),
          amount: movement.amount,
        ),
        isA<Ok<Transaction>>(),
      );
      final paid = (await debts.getById('carro'))!;
      expect(paid.terms!.paidInstallments, 6);
      expect(paid.currentBalance < loan().currentBalance, isTrue);
      final tx = (await transactions.getRecent(limit: 5)).single;
      expect(tx.debtId, 'carro');
      expect(tx.fixedMovementId, movement.id);

      // Desenlazar deja el fijo pero sin crédito.
      await link.unlink((await fixed.getAll()).single);
      expect((await fixed.getAll()).single.debtId, isNull);
    });

    test('el aviso dice cuántas cuotas y cuánto saldo quedan', () {
      final debt = loan();
      final movement = FixedMovement(
        id: 'f',
        name: 'Cuota Carro',
        kind: TransactionKind.expense,
        amount: const Money.pesos(1000000),
        categoryId: DefaultCategories.debtsId,
        dayOfMonth: 20,
        debtId: debt.id,
      );
      final now = DateTime(2026, 10, 12, 9);
      final summary = const CycleSummaryBuilder().build(
        cycle: PayCycle.containing(now, payday: 1),
        today: now,
        cycleTransactions: const [],
        previousCycleTransactions: const [],
        categories: DefaultCategories.all,
        fixedMovements: [movement],
        settings: const FinanceSettings(),
      );
      final reminders = const ReminderPlanner().plan(
        settings: const FinanceSettings(),
        now: now,
        summary: summary,
        debts: [debt],
      );
      final eve = reminders.firstWhere((r) => r.title == 'Mañana: Cuota Carro');
      expect(eve.body, contains('te quedan 18 cuotas de Carro'));
    });
  });
}

double _pow(double base, int exponent) {
  var result = 1.0;
  for (var i = 0; i < exponent.abs(); i++) {
    result *= base;
  }
  return exponent < 0 ? 1 / result : result;
}
