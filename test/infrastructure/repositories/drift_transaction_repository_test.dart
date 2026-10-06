import 'package:finance_app/domain/accounts/account.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late DriftTransactionRepository repository;

  const food = 'seed-expense-food';
  const october = YearMonth(2026, 10);

  Transaction transaction(String id, DateTime date, {String? description}) =>
      Transaction(
        id: id,
        kind: TransactionKind.expense,
        amount: const Money.pesos(5000),
        categoryId: food,
        date: date,
        createdAt: date,
        description: description,
      );

  setUp(() => repository = DriftTransactionRepository(createTestDatabase()));

  test('guarda y recupera todos los campos', () async {
    final full = Transaction(
      id: 't1',
      kind: TransactionKind.expense,
      amount: const Money.pesos(5000),
      categoryId: food,
      date: DateTime(2026, 10, 2, 12),
      createdAt: DateTime(2026, 10, 2, 12, 0, 5),
      description: 'Mercado',
      accountId: Account.defaultCash.id,
      nature: ExpenseNature.essential,
      notes: 'Semana',
    );
    await repository.save(full);

    expect(await repository.getById('t1'), full);
  });

  test('un segundo save actualiza y puede limpiar opcionales', () async {
    await repository.save(
      transaction('t1', DateTime(2026, 10, 2), description: 'Mercado'),
    );
    await repository.save(transaction('t1', DateTime(2026, 10, 2)));

    expect((await repository.getById('t1'))!.description, isNull);
  });

  test('filtra por período [inicio, fin) y ordena del más reciente', () async {
    await repository.save(transaction('sep', DateTime(2026, 9, 30, 23, 59)));
    await repository.save(transaction('oct1', DateTime(2026, 10)));
    await repository.save(transaction('oct15', DateTime(2026, 10, 15)));
    await repository.save(transaction('nov', DateTime(2026, 11)));

    final result = await repository.getByPeriod(october.range);

    expect(result.map((t) => t.id), ['oct15', 'oct1']);
  });

  test('últimos movimientos con límite', () async {
    for (var day = 1; day <= 5; day++) {
      await repository.save(transaction('d$day', DateTime(2026, 10, day)));
    }

    final recent = await repository.getRecent(limit: 2);

    expect(recent.map((t) => t.id), ['d5', 'd4']);
  });

  test('watchByPeriod emite al guardar y al borrar', () async {
    final emissions = repository
        .watchByPeriod(october.range)
        .map((list) => list.map((t) => t.id).toList());

    final expectation = expectLater(
      emissions,
      emitsInOrder([
        isEmpty,
        ['t1'],
        isEmpty,
      ]),
    );

    await pumpEventQueue();
    await repository.save(transaction('t1', DateTime(2026, 10, 3)));
    await pumpEventQueue();
    await repository.delete('t1');
    await expectation;
  });
}
