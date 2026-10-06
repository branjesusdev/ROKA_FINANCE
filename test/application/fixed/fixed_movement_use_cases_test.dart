import 'package:finance_app/application/fixed/fixed_movement_use_cases.dart';
import 'package:finance_app/application/settings/cycle_settings_use_cases.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
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
  const housing = 'seed-expense-housing';
  const salary = 'seed-income-salary';

  late DriftFixedMovementRepository fixed;
  late DriftTransactionRepository transactions;
  late DriftSettingsRepository settings;
  late FixedClock clock;
  late SaveFixedMovement save;
  late PostDueFixedMovements postDue;

  setUp(() {
    final db = createTestDatabase();
    fixed = DriftFixedMovementRepository(db);
    transactions = DriftTransactionRepository(db);
    settings = DriftSettingsRepository(db);
    clock = FixedClock(DateTime(2026, 10, 3, 18));
    final ids = SequentialIds();
    save = SaveFixedMovement(
      fixed: fixed,
      settings: settings,
      clock: clock,
      ids: ids,
    );
    postDue = PostDueFixedMovements(
      fixed: fixed,
      transactions: transactions,
      settings: settings,
      clock: clock,
      ids: ids,
    );
  });

  Future<List<Transaction>> all() =>
      transactions.getByPeriod(DateRange(DateTime(2026), DateTime(2028)));

  int posted(Result<int> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Falló: ${failure.message}'),
  };

  test('registra los fijos del ciclo una sola vez', () async {
    await save(
      name: 'Arriendo',
      kind: TransactionKind.expense,
      amount: const Money.pesos(1200000),
      categoryId: housing,
      dayOfMonth: 1,
    );
    await save(
      name: 'Sueldo',
      kind: TransactionKind.income,
      amount: const Money.pesos(5000000),
      categoryId: salary,
      dayOfMonth: 20,
    );
    await save(
      name: 'Colegio',
      kind: TransactionKind.expense,
      amount: const Money.pesos(400000),
      categoryId: 'seed-expense-education',
      dayOfMonth: 10,
    );

    expect(posted(await postDue()), 2);
    expect(posted(await postDue()), 0, reason: 'idempotente');

    final registered = await all();
    expect(registered.map((t) => t.description), ['Arriendo', 'Sueldo']);
    expect(registered.first.date, DateTime(2026, 10));
    expect(registered.first.nature, ExpenseNature.essential);

    // Llega el día del colegio.
    clock.value = DateTime(2026, 10, 10, 8);
    expect(posted(await postDue()), 1);

    // Nuevo ciclo: todo vuelve a registrarse.
    clock.value = DateTime(2026, 11, 1, 8);
    expect(
      posted(await postDue()),
      2,
      reason: 'sueldo 20 oct y arriendo 1 nov',
    );
  });

  test('borrar el movimiento generado no lo vuelve a crear', () async {
    await save(
      name: 'Arriendo',
      kind: TransactionKind.expense,
      amount: const Money.pesos(1200000),
      categoryId: housing,
      dayOfMonth: 1,
    );
    await postDue();
    await transactions.delete((await all()).single.id);

    expect(posted(await postDue()), 0);
  });

  test('si ya se anotó a mano no se registra en este ciclo', () async {
    await save(
      name: 'Arriendo',
      kind: TransactionKind.expense,
      amount: const Money.pesos(1200000),
      categoryId: housing,
      dayOfMonth: 1,
      registerInCurrentCycle: false,
    );

    expect(posted(await postDue()), 0);
    clock.value = DateTime(2026, 11);
    expect(posted(await postDue()), 1);
  });

  test('respeta el día de pago configurado', () async {
    await UpdatePayday(settings).call(1);
    await save(
      name: 'Sueldo',
      kind: TransactionKind.income,
      amount: const Money.pesos(5000000),
      categoryId: salary,
      dayOfMonth: 20,
    );

    expect(posted(await postDue()), 0, reason: 'ciclo 1–31 oct, día 20');
  });

  test('valida nombre, valor y día', () async {
    Future<String?> code({
      String name = 'Arriendo',
      int pesos = 1000,
      int day = 1,
    }) async {
      final result = await save(
        name: name,
        kind: TransactionKind.expense,
        amount: Money.pesos(pesos),
        categoryId: housing,
        dayOfMonth: day,
      );
      return switch (result) {
        Err(failure: ValidationFailure(:final message)) => message,
        _ => null,
      };
    }

    expect(await code(name: '  '), 'name_required');
    expect(await code(pesos: 0), 'amount_must_be_positive');
    expect(await code(day: 32), 'day_out_of_range');
    expect(await code(), isNull);
  });
}
