import 'package:finance_app/application/transactions/update_transaction.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late FakeTransactionRepository repository;
  late UpdateTransaction update;
  final created = DateTime(2026, 10, 1, 8);
  final original = Transaction(
    id: 'tx-1',
    kind: TransactionKind.expense,
    amount: const Money.pesos(5000),
    categoryId: 'food',
    date: DateTime(2026, 10, 3),
    createdAt: created,
    notes: 'nota',
    fixedMovementId: 'rent',
  );

  setUp(() async {
    repository = FakeTransactionRepository();
    await repository.save(original);
    update = UpdateTransaction(repository);
  });

  test('corrige monto, categoría, fecha y descripción; conserva vínculos '
      'y creación', () async {
    final result = await update(
      UpdateTransactionInput(
        id: 'tx-1',
        kind: TransactionKind.expense,
        amount: const Money.pesos(7000),
        categoryId: 'transport',
        date: DateTime(2026, 10, 2),
        description: '  Taxi ',
        nature: ExpenseNature.discretionary,
      ),
    );

    final saved = repository.saved['tx-1']!;
    expect(result, isA<Ok<Transaction>>());
    expect(saved.amount, const Money.pesos(7000));
    expect(saved.categoryId, 'transport');
    expect(saved.date, DateTime(2026, 10, 2));
    expect(saved.description, 'Taxi');
    expect(saved.nature, ExpenseNature.discretionary);
    expect(saved.createdAt, created);
    expect(saved.notes, 'nota');
    expect(saved.fixedMovementId, 'rent');
  });

  test(
    'descripción vacía queda sin descripción; ingreso sin naturaleza',
    () async {
      await update(
        UpdateTransactionInput(
          id: 'tx-1',
          kind: TransactionKind.income,
          amount: const Money.pesos(5000),
          categoryId: 'salary',
          date: original.date,
          description: '   ',
          nature: ExpenseNature.essential,
        ),
      );

      final saved = repository.saved['tx-1']!;
      expect(saved.description, isNull);
      expect(saved.nature, isNull);
    },
  );

  test('rechaza monto en cero sin tocar el movimiento', () async {
    final result = await update(
      UpdateTransactionInput(
        id: 'tx-1',
        kind: TransactionKind.expense,
        amount: Money.zero,
        categoryId: 'food',
        date: original.date,
      ),
    );

    expect(result, isA<Err<Transaction>>());
    expect(repository.saved['tx-1'], original);
  });

  test('movimiento inexistente: NotFoundFailure', () async {
    final result = await update(
      UpdateTransactionInput(
        id: 'otro',
        kind: TransactionKind.expense,
        amount: const Money.pesos(1),
        categoryId: 'food',
        date: original.date,
      ),
    );

    expect(
      result,
      isA<Err<Transaction>>().having(
        (e) => e.failure,
        'failure',
        isA<NotFoundFailure>(),
      ),
    );
  });
}
