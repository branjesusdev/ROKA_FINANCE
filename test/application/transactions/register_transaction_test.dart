import 'package:finance_app/application/transactions/register_transaction.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late FakeTransactionRepository repository;
  late RegisterTransaction register;
  final now = DateTime(2026, 10, 2, 9, 30);

  setUp(() {
    repository = FakeTransactionRepository();
    register = RegisterTransaction(
      transactions: repository,
      clock: FixedClock(now),
      ids: SequentialIds(),
    );
  });

  test('registro rápido: solo monto y categoría, fecha = ahora', () async {
    final result = await register(
      const RegisterTransactionInput(
        kind: TransactionKind.expense,
        amount: Money.pesos(5000),
        categoryId: 'food',
        description: '  Mercado ',
      ),
    );

    final saved = repository.saved['id-1']!;
    expect(result, isA<Ok<Transaction>>());
    expect(saved.date, now);
    expect(saved.createdAt, now);
    expect(saved.description, 'Mercado');
  });

  test('rechaza montos en cero sin guardar', () async {
    final result = await register(
      const RegisterTransactionInput(
        kind: TransactionKind.expense,
        amount: Money.zero,
        categoryId: 'food',
      ),
    );

    expect(
      result,
      isA<Err<Transaction>>().having(
        (e) => e.failure,
        'failure',
        isA<ValidationFailure>(),
      ),
    );
    expect(repository.saved, isEmpty);
  });

  test('los ingresos no guardan naturaleza de gasto', () async {
    await register(
      const RegisterTransactionInput(
        kind: TransactionKind.income,
        amount: Money.pesos(7000000),
        categoryId: 'salary',
        nature: ExpenseNature.essential,
      ),
    );

    expect(repository.saved['id-1']!.nature, isNull);
  });

  test('un fallo de almacenamiento se devuelve como StorageFailure', () async {
    repository.failing = true;

    final result = await register(
      const RegisterTransactionInput(
        kind: TransactionKind.expense,
        amount: Money.pesos(5000),
        categoryId: 'food',
      ),
    );

    expect(
      result,
      isA<Err<Transaction>>().having(
        (e) => e.failure,
        'failure',
        isA<StorageFailure>(),
      ),
    );
  });
}
