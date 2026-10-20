import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;

import 'package:finance_app/application/backup/backup_ports.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/backup/drift_backup_store.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/drift_asset_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_category_repository.dart';
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
      final report = await DriftBackupStore(target).import(json);

      expect(report.updated, 1, reason: 'la copia es más reciente');
      expect(await DriftFixedMovementRepository(target).getAll(), [
        const FixedMovement(
          id: 'local-rent',
          name: 'Arriendo',
          kind: TransactionKind.expense,
          amount: Money.pesos(900000),
          categoryId: food,
          dayOfMonth: 5,
        ),
      ]);
      expect(
        (await allTransactions(target)).single.fixedMovementId,
        'local-rent',
      );
    },
  );

  test('la copia más reciente actualiza lo que cambió (categoría, fijo, '
      'deuda); una más vieja solo agrega', () async {
    final source = createTestDatabase();
    final categories = DriftCategoryRepository(source);
    final mercado = (await categories.getById(food))!;
    await categories.save(mercado.copyWith(name: 'Mercado y comida'));
    await DriftFixedMovementRepository(source).save(rent);
    final json = await DriftBackupStore(source).export(exportedAt: exportedAt);

    // Teléfono nuevo: la copia gana.
    final fresh = createTestDatabase();
    await DriftFixedMovementRepository(fresh)
        .save(rent.copyWith(amount: const Money.pesos(800000)));
    final report = await DriftBackupStore(fresh).import(json);
    expect(report.olderThanLocal, isFalse);
    expect(report.updated, 2, reason: 'categoría y arriendo');
    expect(
      (await DriftCategoryRepository(fresh).getById(food))!.name,
      'Mercado y comida',
    );
    expect(
      (await DriftFixedMovementRepository(fresh).getAll()).single.amount,
      const Money.pesos(900000),
    );

    // Teléfono con algo anotado después de la copia: no se pisa nada.
    final newer = createTestDatabase();
    await DriftTransactionRepository(newer).save(
      Transaction(
        id: 'late',
        kind: TransactionKind.expense,
        amount: const Money.pesos(1000),
        categoryId: food,
        date: DateTime(2026, 10, 9),
        createdAt: DateTime(2026, 10, 9, 8),
      ),
    );
    final older = await DriftBackupStore(newer).import(json);
    expect(older.olderThanLocal, isTrue);
    expect(older.updated, 0);
    expect(
      (await DriftCategoryRepository(newer).getById(food))!.name,
      isNot('Mercado y comida'),
    );
    expect(older.added, 1, reason: 'el arriendo que faltaba');
  });

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

  group('copia de la versión anterior (esquema v8)', () {
    final v8 = File('test/fixtures/backup_v8.json').readAsStringSync();

    test('importa todo en un teléfono vacío', () async {
      final target = createTestDatabase();
      final report = await DriftBackupStore(target).import(v8);

      expect(report.movementsAdded, 4);
      final tx = await allTransactions(target);
      expect(tx.map((t) => t.id), containsAll(['tx-salary', 'tx-rent']));
      final assets = await DriftAssetRepository(target).getAll();
      expect(assets.single.monthlyCost, Money.zero);
      final categories = await DriftCategoryRepository(target)
          .getAll(includeArchived: true);
      expect(
        categories.firstWhere((c) => c.id == 'user-cat-pets').isExtraordinary,
        isFalse,
      );
      // Las categorías nuevas siguen ahí.
      expect(categories.where((c) => c.isExtraordinary), isNotEmpty);
    });

    test('conserva los ajustes de IA que la copia no trae', () async {
      final target = createTestDatabase();
      final settings = DriftSettingsRepository(target);
      await settings.save(
        (await settings.get()).copyWith(
          aiEnabled: true,
          aiReviewFrequency: ReviewFrequency.daily,
        ),
      );

      await DriftBackupStore(target).import(v8);

      final after = await settings.get();
      expect(after.aiEnabled, isTrue);
      expect(after.aiReviewFrequency, ReviewFrequency.daily);
    });

    test('importarla dos veces no duplica', () async {
      final target = createTestDatabase();
      await DriftBackupStore(target).import(v8);
      final second = await DriftBackupStore(target).import(v8);
      expect(second.added, 0);
    });
  });

  test('exporta el historial de patrimonio y no la llave de IA', () async {
    final source = createTestDatabase();
    await source
        .into(source.aiSecrets)
        .insert(
          AiSecretsCompanion.insert(id: const Value(1), apiKey: 'secreta'),
        );
    await source
        .into(source.netWorthSnapshots)
        .insert(
          NetWorthSnapshotsCompanion.insert(
            id: 'nw-1',
            year: 2026,
            month: 9,
            assetsCents: 100,
            investmentsCents: 0,
            liabilitiesCents: 50,
            takenAt: DateTime(2026, 9, 30),
          ),
        );

    final json = await DriftBackupStore(source).export(exportedAt: exportedAt);

    expect(json, isNot(contains('secreta')));
    final target = createTestDatabase();
    await DriftBackupStore(target).import(json);
    expect(await target.select(target.netWorthSnapshots).get(), hasLength(1));
  });
}
