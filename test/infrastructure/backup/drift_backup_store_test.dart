import 'dart:convert';

import 'package:finance_app/application/backup/backup_ports.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/backup/drift_backup_store.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/drift_fixed_movement_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_settings_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  const food = 'seed-expense-food';
  final exportedAt = DateTime(2026, 10, 8);

  Transaction coffee(String id, {DateTime? date, String? fixedId}) =>
      Transaction(
        id: id,
        kind: TransactionKind.expense,
        amount: const Money.pesos(5000),
        categoryId: food,
        date: date ?? DateTime(2026, 10, 2, 9),
        createdAt: DateTime(2026, 10, 2, 9),
        description: 'Café',
        fixedMovementId: fixedId,
      );

  const rent = FixedMovement(
    id: 'fixed-rent',
    name: 'Arriendo',
    kind: TransactionKind.expense,
    amount: Money.pesos(900000),
    categoryId: food,
    dayOfMonth: 5,
  );

  Future<List<Transaction>> allTransactions(AppDatabase db) async {
    final rows = await db.select(db.transactions).get();
    return [
      for (final r in rows)
        (await DriftTransactionRepository(db).getById(r.id))!,
    ];
  }

  test('exporta e importa todo en un teléfono vacío', () async {
    final source = createTestDatabase();
    await DriftFixedMovementRepository(source).save(rent);
    await DriftTransactionRepository(source).save(coffee('t1'));
    await DriftTransactionRepository(source)
        .save(coffee('t2', date: DateTime(2026, 9, 3), fixedId: rent.id));
    final settings = DriftSettingsRepository(source);
    await settings.save((await settings.get()).copyWith(payday: 15));

    final json = await DriftBackupStore(source).export(exportedAt: exportedAt);

    final target = createTestDatabase();
    final report = await DriftBackupStore(target).import(json);

    expect(report.movementsAdded, 2);
    expect(
      await allTransactions(target),
      unorderedEquals(await allTransactions(source)),
    );
    expect(
      (await DriftFixedMovementRepository(target).getAll()).single.name,
      'Arriendo',
    );
    expect((await DriftSettingsRepository(target).get()).payday, 15);
  });

  test('importar dos veces no duplica', () async {
    final db = createTestDatabase();
    await DriftTransactionRepository(db).save(coffee('t1'));
    final store = DriftBackupStore(db);
    final json = await store.export(exportedAt: exportedAt);

    final report = await store.import(json);

    expect(report.added, 0);
    expect(await allTransactions(db), hasLength(1));
  });

  test(
    'un gasto igual con otro id no se duplica; uno extra sí entra',
    () async {
      final source = createTestDatabase();
      final repo = DriftTransactionRepository(source);
      await repo.save(coffee('a'));
      await repo.save(coffee('b'));
      final json = await DriftBackupStore(source)
          .export(exportedAt: exportedAt);

      final target = createTestDatabase();
      await DriftTransactionRepository(target).save(coffee('local'));
      final report = await DriftBackupStore(target).import(json);

      expect(report.movementsAdded, 1);
      expect(await allTransactions(target), hasLength(2));
    },
  );

  test(
    'los movimientos de un fijo equivalente apuntan al fijo local',
    () async {
      final source = createTestDatabase();
      await DriftFixedMovementRepository(source).save(rent);
      await DriftTransactionRepository(source)
          .save(coffee('t1', fixedId: rent.id));
      final json = await DriftBackupStore(source)
          .export(exportedAt: exportedAt);

      final target = createTestDatabase();
      const localRent = FixedMovement(
        id: 'local-rent',
        name: 'Arriendo',
        kind: TransactionKind.expense,
        amount: Money.pesos(950000),
        categoryId: food,
        dayOfMonth: 5,
      );
      await DriftFixedMovementRepository(target).save(localRent);
      await DriftBackupStore(target).import(json);

      expect(await DriftFixedMovementRepository(target).getAll(), [localRent]);
      expect(
        (await allTransactions(target)).single.fixedMovementId,
        'local-rent',
      );
    },
  );

  test('rechaza archivos ajenos y de versiones más nuevas', () async {
    final store = DriftBackupStore(createTestDatabase());

    expect(() => store.import('hola'), throwsA(isA<InvalidBackupException>()));
    expect(
      () =>
          store.import(jsonEncode({'app': 'otra', 'data': <String, Object>{}})),
      throwsA(isA<InvalidBackupException>()),
    );
    expect(
      () => store.import(
        jsonEncode({
          'app': DriftBackupStore.appId,
          'format': DriftBackupStore.formatVersion + 1,
          'schemaVersion': 1,
          'data': <String, Object>{},
        }),
      ),
      throwsA(
        isA<InvalidBackupException>().having(
          (e) => e.newerVersion,
          'newer',
          true,
        ),
      ),
    );
  });

  test('un registro dañado no deja nada a medias', () async {
    final source = createTestDatabase();
    await DriftTransactionRepository(source).save(coffee('t1'));
    final backup = jsonDecode(
      await DriftBackupStore(source).export(exportedAt: exportedAt),
    ) as Map<String, Object?>;
    final data = backup['data']! as Map<String, Object?>;
    (data['transactions']! as List<Object?>).add({'id': 'roto'});

    final target = createTestDatabase();
    await expectLater(
      DriftBackupStore(target).import(jsonEncode(backup)),
      throwsA(isA<InvalidBackupException>()),
    );
    expect(await allTransactions(target), isEmpty);
  });
}
