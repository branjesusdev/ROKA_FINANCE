import 'package:finance_app/application/cycles/load_current_cycle.dart';
import 'package:finance_app/application/fixed/fixed_movement_use_cases.dart';
import 'package:finance_app/application/transactions/reset_cycle_movements.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/shared/date_range.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/repositories/drift_fixed_movement_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_settings_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';
import '../../support/test_database.dart';

void main() {
  const food = 'seed-expense-food';
  const housing = 'seed-expense-housing';

  late DriftTransactionRepository transactions;
  late DriftFixedMovementRepository fixed;
  late ResetCycleMovements reset;
  late PostDueFixedMovements postDue;
  late SaveFixedMovement saveFixed;

  setUp(() {
    final db = createTestDatabase();
    transactions = DriftTransactionRepository(db);
    fixed = DriftFixedMovementRepository(db);
    final settings = DriftSettingsRepository(db);
    final clock = FixedClock(DateTime(2026, 10, 10, 12));
    final ids = SequentialIds();
    final currentCycle = LoadCurrentCycle(
      settings: settings,
      transactions: transactions,
    );
    reset = ResetCycleMovements(
      currentCycle: currentCycle,
      transactions: transactions,
      clock: clock,
    );
    saveFixed = SaveFixedMovement(
      fixed: fixed,
      currentCycle: currentCycle,
      clock: clock,
      ids: ids,
    );
    postDue = PostDueFixedMovements(
      fixed: fixed,
      transactions: transactions,
      currentCycle: currentCycle,
      clock: clock,
      ids: ids,
    );
  });

  Future<List<Transaction>> all() =>
      transactions.getByPeriod(DateRange(DateTime(2026), DateTime(2028)));

  test('borra lo anotado a mano en el ciclo; conserva fijos, apartados y '
      'la configuración de fijos', () async {
    final cycle = (await reset.preview()).fold(
      onOk: (p) => p.cycle,
      onErr: (f) => fail(f.message),
    );
    await saveFixed(
      name: 'Arriendo',
      kind: TransactionKind.expense,
      amount: const Money.pesos(1200000),
      categoryId: housing,
      dayOfMonth: cycle.start.day,
    );
    await postDue();
    final day = cycle.start.add(const Duration(days: 1));
    final manual = expense(25000, category: food, date: day);
    final provision = Transaction(
      id: 'set-aside',
      kind: TransactionKind.expense,
      amount: const Money.pesos(40000),
      categoryId: food,
      date: day,
      createdAt: day,
      provisionId: 'soat',
    );
    final outside = expense(
      9000,
      category: food,
      date: cycle.start.subtract(const Duration(days: 1)),
    );
    for (final t in [manual, provision, outside]) {
      await transactions.save(t);
    }

    final removed = (await reset()).fold(
      onOk: (r) => r.map((t) => t.id).toList(),
      onErr: (f) => fail(f.message),
    );

    expect(removed, [manual.id]);
    final remaining = await all();
    expect(remaining.map((t) => t.id), isNot(contains(manual.id)));
    expect(remaining.map((t) => t.id), containsAll([provision.id, outside.id]));
    expect(
      remaining.where((t) => t.fixedMovementId != null),
      hasLength(1),
      reason: 'el arriendo generado por el fijo se conserva',
    );
    expect(await fixed.getAll(), hasLength(1));
  });

  test('deshacer restaura lo borrado', () async {
    final cycle = (await reset.preview()).fold(
      onOk: (p) => p.cycle,
      onErr: (f) => fail(f.message),
    );
    final manual = expense(25000, category: food, date: cycle.start);
    await transactions.save(manual);

    final removed = (await reset()).fold(
      onOk: (r) => r,
      onErr: (f) => fail(f.message),
    );
    expect(await all(), isEmpty);

    expect(await reset.undo(removed), isA<Ok<void>>());
    expect(await all(), [manual]);
  });
}
