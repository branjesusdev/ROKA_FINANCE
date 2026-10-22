import 'package:finance_app/application/cycles/load_current_cycle.dart';
import 'package:finance_app/application/cycles/reconcile_balance.dart';
import 'package:finance_app/application/transactions/cycle_movements.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/cycle_recount.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/shared/date_range.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/repositories/drift_fixed_movement_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_settings_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_database.dart';

void main() {
  test('desbalance: menos de 50 mil normal, hasta 100 mil aviso, más rojo', () {
    expect(RecountLevel.of(const Money.pesos(-49999)), RecountLevel.fine);
    expect(RecountLevel.of(const Money.pesos(-50000)), RecountLevel.warning);
    expect(RecountLevel.of(const Money.pesos(100000)), RecountLevel.warning);
    expect(RecountLevel.of(const Money.pesos(-100001)), RecountLevel.alert);
  });

  test(
    'el reconteo al llegar el sueldo cuadra el ciclo que se cierra',
    () async {
      final db = createTestDatabase();
      final transactions = DriftTransactionRepository(db);
      final ids = SequentialIds();
      var seq = 0;
      Future<void> tx(
        int pesos,
        DateTime date,
        String category, {
        TransactionKind kind = TransactionKind.expense,
      }) => transactions.save(
        Transaction(
          id: 'tx${seq++}',
          kind: kind,
          amount: Money.pesos(pesos),
          categoryId: category,
          date: date,
          createdAt: date,
        ),
      );
      await tx(
        3000000,
        DateTime(2026, 9, 20),
        DefaultCategories.salaryId,
        kind: TransactionKind.income,
      );
      await tx(2500000, DateTime(2026, 10, 2), 'seed-expense-housing');

      final reconcile = ReconcileBalance(
        currentCycle: LoadCurrentCycle(
          settings: DriftSettingsRepository(db),
          transactions: transactions,
        ),
        transactions: transactions,
        fixed: DriftFixedMovementRepository(db),
        clock: FixedClock(DateTime(2026, 10, 20, 9)),
        ids: ids,
      );

      final result = await reconcile(
        actual: const Money.pesos(380000),
        closingOn: DateTime(2026, 10, 19),
      );

      final value = switch (result) {
        Ok(:final value) => value,
        Err(:final failure) => fail(failure.message),
      };
      expect(value.registered, const Money.pesos(500000));
      expect(value.difference, const Money.pesos(-120000));

      final all = await transactions.getByPeriod(
        DateRange(DateTime(2026), DateTime(2027)),
      );
      final gap = all.singleWhere(
        (t) => t.description == ReconcileBalance.recountDescription,
      );
      expect(gap.date, DateTime(2026, 10, 19));
      expect(gap.categoryId, DefaultCategories.untracked.id);

      final movements = const CycleMovementsBuilder().build(
        cycle: PayCycle.containing(DateTime(2026, 10, 19), payday: 20),
        transactions: all,
        categories: DefaultCategories.all,
      );
      final recount = movements.recount!;
      expect(recount.difference, const Money.pesos(-120000));
      expect(recount.actualLeft, const Money.pesos(380000));
      expect(recount.registeredLeft, const Money.pesos(500000));
      expect(recount.level, RecountLevel.alert);
    },
  );
}
