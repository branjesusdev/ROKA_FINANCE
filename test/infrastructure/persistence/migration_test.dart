import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/drift_asset_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_category_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_fixed_movement_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_investment_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_provision_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_settings_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  late Directory dir;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = await Directory.systemTemp.createTemp('finance_migration');
  });

  tearDown(() => dir.delete(recursive: true));

  AppDatabase open(File file) => AppDatabase(NativeDatabase(file));

  /// Quita lo que agregó v14 a una base recién creada.
  Future<void> downgradeToV13(AppDatabase db) async {
    await db.customStatement(
      'ALTER TABLE finance_settings DROP COLUMN monthly_salary_cents',
    );
    await db.customStatement('PRAGMA user_version = 13');
  }

  /// Quita lo que agregaron v13 y v14.
  Future<void> downgradeToV12(AppDatabase db) async {
    await downgradeToV13(db);
    await db.customStatement(
      'ALTER TABLE fixed_movements DROP COLUMN auto_debit',
    );
    await db.customStatement('PRAGMA user_version = 12');
  }

  /// Quita lo que agregaron v12 y v13.
  Future<void> downgradeToV11(AppDatabase db) async {
    await downgradeToV12(db);
    await db.customStatement(
      'ALTER TABLE fixed_movements DROP COLUMN remind_on',
    );
    await db.customStatement('PRAGMA user_version = 11');
  }

  /// Quita lo que agregaron v11 y v12.
  Future<void> downgradeToV10(AppDatabase db) async {
    await downgradeToV11(db);
    await db.customStatement(
      'ALTER TABLE transactions DROP COLUMN odometer_km',
    );
    await db.customStatement(
      'ALTER TABLE investments DROP COLUMN invested_usd_cents',
    );
    await db.customStatement('ALTER TABLE fixed_movements DROP COLUMN debt_id');
    await db.customStatement('PRAGMA user_version = 10');
  }

  /// Quita lo que agregaron v10 y v11.
  Future<void> downgradeToV9(AppDatabase db) async {
    await downgradeToV10(db);
    for (final column in ['symbol', 'units_micros', 'price_updated_at']) {
      await db.customStatement('ALTER TABLE investments DROP COLUMN $column');
    }
    await db.customStatement('PRAGMA user_version = 9');
  }

  /// Quita lo que agregaron v9 y v10.
  Future<void> downgradeToV8(AppDatabase db) async {
    await downgradeToV9(db);
    await db.customStatement(
      'ALTER TABLE categories DROP COLUMN is_extraordinary',
    );
    for (final column in [
      'monthly_cost_cents',
      'monthly_income_cents',
      'liquidity',
      'linked_debt_id',
    ]) {
      await db.customStatement('ALTER TABLE assets DROP COLUMN $column');
    }
    for (final column in ['ai_enabled', 'ai_review_frequency']) {
      await db.customStatement(
        'ALTER TABLE finance_settings DROP COLUMN $column',
      );
    }
    for (final table in ['net_worth_snapshots', 'ai_reviews', 'ai_secrets']) {
      await db.customStatement('DROP TABLE $table');
    }
    for (final category in DefaultCategories.extraordinaryIncomes) {
      await db.customStatement(
        "DELETE FROM categories WHERE id = '${category.id}'",
      );
    }
    await db.customStatement('PRAGMA user_version = 8');
  }

  /// Quita lo que agregaron v8 y v9.
  Future<void> downgradeToV7(AppDatabase db) async {
    await downgradeToV8(db);
    await db.customStatement(
      'ALTER TABLE finance_settings DROP COLUMN appearance',
    );
    await db.customStatement('PRAGMA user_version = 7');
  }

  /// Quita lo que agregaron v7 y v8.
  Future<void> downgradeToV6(AppDatabase db) async {
    await downgradeToV7(db);
    await db.customStatement(
      'ALTER TABLE fixed_movements DROP COLUMN is_variable',
    );
    await db.customStatement('PRAGMA user_version = 6');
  }

  /// Quita lo que agregaron v6 y v7.
  Future<void> downgradeToV5(AppDatabase db) async {
    await downgradeToV6(db);
    await db.customStatement(
      'ALTER TABLE transactions DROP COLUMN fixed_movement_id',
    );
    await db.customStatement('PRAGMA user_version = 5');
  }

  /// Quita lo que agregaron v5 y v6.
  Future<void> downgradeToV4(AppDatabase db) async {
    await downgradeToV5(db);
    await db.customStatement('DROP TABLE provisions');
    await db.customStatement(
      'ALTER TABLE transactions DROP COLUMN provision_id',
    );
    await db.customStatement(
      "DELETE FROM categories WHERE id = '${DefaultCategories.provisions.id}'",
    );
    await db.customStatement('PRAGMA user_version = 4');
  }

  /// Quita lo que agregaron v4 y v5.
  Future<void> downgradeToV3(AppDatabase db) async {
    await downgradeToV4(db);
    for (final column in [
      'dependents',
      'solo_provider',
      'kids_monthly_buffer_cents',
    ]) {
      await db.customStatement(
        'ALTER TABLE finance_settings DROP COLUMN $column',
      );
    }
    for (final category in [
      DefaultCategories.untracked,
      DefaultCategories.balanceAdjustment,
    ]) {
      await db.customStatement(
        "DELETE FROM categories WHERE id = '${category.id}'",
      );
    }
    await db.customStatement('PRAGMA user_version = 3');
  }

  /// Quita lo que agregaron v3 en adelante.
  Future<void> downgradeToV2(AppDatabase db) async {
    await downgradeToV3(db);
    for (final column in ['reminder_minute', 'smart_notifications']) {
      await db.customStatement(
        'ALTER TABLE finance_settings DROP COLUMN $column',
      );
    }
    await db.customStatement(
      "DELETE FROM categories WHERE id = '${DefaultCategories.groceries.id}'",
    );
    await db.customStatement('PRAGMA user_version = 2');
  }

  test('v13 → v14 conserva ajustes y agrega el sueldo', () async {
    final file = File('${dir.path}/db.sqlite');
    final v13 = open(file);
    await DriftSettingsRepository(v13).save(const FinanceSettings(payday: 15));
    await downgradeToV13(v13);
    await v13.close();

    final v14 = open(file);
    addTearDown(v14.close);
    final settings = DriftSettingsRepository(v14);
    expect((await settings.get()).payday, 15);
    expect((await settings.get()).monthlySalary, Money.zero);
    await settings.save(
      const FinanceSettings(payday: 15, monthlySalary: Money.pesos(3400000)),
    );
    expect((await settings.get()).monthlySalary, const Money.pesos(3400000));
  });

  test('v12 → v13: los gastos fijos pasan a pedir "Ya lo pagué"', () async {
    final file = File('${dir.path}/db.sqlite');
    final v12 = open(file);
    const rent = FixedMovement(
      id: 'rent',
      name: 'Arriendo',
      kind: TransactionKind.expense,
      amount: Money.pesos(900000),
      categoryId: 'seed-expense-housing',
      dayOfMonth: 14,
    );
    await DriftFixedMovementRepository(v12).save(rent);
    await downgradeToV12(v12);
    await v12.close();

    final v13 = open(file);
    addTearDown(v13.close);
    final repo = DriftFixedMovementRepository(v13);
    final migrated = (await repo.getAll()).single;
    expect(migrated, rent);
    expect(migrated.needsConfirmation, isTrue);
    await repo.save(migrated.copyWith(autoDebit: true));
    expect((await repo.getAll()).single.autoDebit, isTrue);
  });

  test('v11 → v12 conserva los fijos y agrega "recuérdame"', () async {
    final file = File('${dir.path}/db.sqlite');
    final v11 = open(file);
    const luz = FixedMovement(
      id: 'luz',
      name: 'Luz',
      kind: TransactionKind.expense,
      amount: Money.pesos(120000),
      categoryId: 'seed-expense-services',
      dayOfMonth: 13,
      isVariable: true,
    );
    await DriftFixedMovementRepository(v11).save(luz);
    await downgradeToV11(v11);
    await v11.close();

    final v12 = open(file);
    addTearDown(v12.close);
    final repo = DriftFixedMovementRepository(v12);
    expect((await repo.getAll()).single, luz);
    await repo.save(luz.remindedOn(DateTime(2026, 10, 14)));
    expect((await repo.getAll()).single.remindOn, DateTime(2026, 10, 14));
  });

  test('v10 → v11 agrega kilometraje, dólares y crédito del fijo', () async {
    final file = File('${dir.path}/db.sqlite');
    final v10 = open(file);
    await v10
        .into(v10.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 'gas',
            kind: TransactionKind.expense,
            amountCents: 10000000,
            categoryId: 'seed-expense-transport',
            date: DateTime(2026, 10),
            createdAt: DateTime(2026, 10),
          ),
        );
    await downgradeToV10(v10);
    await v10.close();

    final v11 = open(file);
    addTearDown(v11.close);
    final repo = DriftTransactionRepository(v11);
    final gas = (await repo.getRecent(limit: 5)).single;
    expect(gas.odometerKm, isNull);
    await repo.save(
      Transaction(
        id: 'gas2',
        kind: TransactionKind.expense,
        amount: const Money.pesos(100000),
        categoryId: 'seed-expense-transport',
        date: DateTime(2026, 10, 9),
        createdAt: DateTime(2026, 10, 9),
        odometerKm: 45200,
      ),
    );
    expect(
      (await repo.getById('gas2'))!.odometerKm,
      45200,
      reason: 'la columna nueva guarda y lee',
    );
  });

  test('v9 → v10 conserva inversiones y agrega símbolo y cantidad', () async {
    final file = File('${dir.path}/db.sqlite');
    final v9 = open(file);
    await v9
        .into(v9.investments)
        .insert(
          InvestmentsCompanion.insert(
            id: 'fondo',
            name: 'Fondo',
            type: InvestmentType.fund,
            investedCents: 100000,
            currentValueCents: 120000,
            date: DateTime(2026),
          ),
        );
    await downgradeToV9(v9);
    await v9.close();

    final v10 = open(file);
    addTearDown(v10.close);
    final repo = DriftInvestmentRepository(v10);
    final fondo = (await repo.getAll()).single;
    expect(fondo.currentValue, const Money(120000));
    expect(fondo.symbol, isNull);
    expect(fondo.isMarketPriced, isFalse);

    await repo.save(
      Investment(
        id: 'nvda',
        name: 'Nvidia',
        type: InvestmentType.stocks,
        investedAmount: const Money.pesos(1000000),
        currentValue: const Money.pesos(1000000),
        date: DateTime(2026, 5),
        symbol: 'NVDA',
        unitsMicros: 2500000,
        priceUpdatedAt: DateTime(2026, 10, 12, 9),
      ),
    );
    final nvda = (await repo.getAll()).firstWhere((i) => i.id == 'nvda');
    expect(nvda.units, 2.5);
    expect(nvda.priceUpdatedAt, DateTime(2026, 10, 12, 9));
  });

  test(
    'v8 → v9 conserva datos y agrega ingresos extraordinarios e IA',
    () async {
      final file = File('${dir.path}/db.sqlite');
      final v8 = open(file);
      await DriftSettingsRepository(v8)
          .save(const FinanceSettings(payday: 15, appearance: Appearance.dark));
      await v8
          .into(v8.assets)
          .insert(
            AssetsCompanion.insert(
              id: 'car',
              name: 'Carro',
              type: AssetType.vehicle,
              currentValueCents: 100,
              valuedAt: DateTime(2026, 10),
            ),
          );
      await downgradeToV8(v8);
      await v8.close();

      final v9 = open(file);
      addTearDown(v9.close);
      final settings = await DriftSettingsRepository(v9).get();
      expect(settings.payday, 15);
      expect(settings.appearance, Appearance.dark);
      expect(settings.aiEnabled, isFalse);
      expect(settings.aiReviewFrequency, ReviewFrequency.weekly);
      final categories = await DriftCategoryRepository(v9)
          .getAll(includeArchived: true);
      final byId = {for (final c in categories) c.id: c};
      expect(byId[DefaultCategories.extraordinaryId]!.isExtraordinary, isTrue);
      for (final category in DefaultCategories.extraordinaryIncomes) {
        expect(byId[category.id]?.isExtraordinary, isTrue);
      }
      expect(byId[DefaultCategories.salaryId]!.isExtraordinary, isFalse);
      final asset = (await DriftAssetRepository(v9).getAll()).single;
      expect(asset.monthlyCost, Money.zero);
      expect(asset.effectiveLiquidity, Liquidity.low);
    },
  );

  test('v7 → v8 conserva ajustes y agrega apariencia', () async {
    final file = File('${dir.path}/db.sqlite');
    final v7 = open(file);
    await DriftSettingsRepository(v7).save(const FinanceSettings(payday: 15));
    await downgradeToV7(v7);
    await v7.close();

    final v8 = open(file);
    addTearDown(v8.close);
    final settings = DriftSettingsRepository(v8);
    expect((await settings.get()).payday, 15);
    expect((await settings.get()).appearance, Appearance.system);
    await settings.save(
      const FinanceSettings(payday: 15, appearance: Appearance.dark),
    );
    expect((await settings.get()).appearance, Appearance.dark);
  });

  test('v6 → v7 conserva los fijos como de valor fijo', () async {
    final file = File('${dir.path}/db.sqlite');
    final v6 = open(file);
    const rent = FixedMovement(
      id: 'rent',
      name: 'Arriendo',
      kind: TransactionKind.expense,
      amount: Money.pesos(1200000),
      categoryId: 'seed-expense-housing',
      dayOfMonth: 1,
    );
    await DriftFixedMovementRepository(v6).save(rent);
    await downgradeToV6(v6);
    await v6.close();

    final v7 = open(file);
    addTearDown(v7.close);
    final repository = DriftFixedMovementRepository(v7);
    expect(await repository.getAll(), [rent]);
    final light = rent.copyWith(name: 'Luz', isVariable: true);
    await repository.save(light);
    expect((await repository.getAll()).single.isVariable, isTrue);
  });

  test('v5 → v6 vincula los movimientos ya generados por fijos', () async {
    final file = File('${dir.path}/db.sqlite');
    final v5 = open(file);
    const rent = FixedMovement(
      id: 'rent',
      name: 'Arriendo',
      kind: TransactionKind.expense,
      amount: Money.pesos(1200000),
      categoryId: 'seed-expense-housing',
      dayOfMonth: 1,
    );
    await DriftFixedMovementRepository(v5).save(rent);
    final repository = DriftTransactionRepository(v5);
    final posted = Transaction(
      id: 'posted',
      kind: TransactionKind.expense,
      amount: rent.amount,
      categoryId: rent.categoryId,
      date: DateTime(2026, 10),
      createdAt: DateTime(2026, 10),
      description: rent.name,
    );
    await repository.save(posted);
    await repository.save(expense(5000, category: 'seed-expense-food'));
    await downgradeToV5(v5);
    await v5.close();

    final v6 = open(file);
    addTearDown(v6.close);
    final transactions = await DriftTransactionRepository(v6)
        .getRecent(limit: 5);
    expect({
      for (final t in transactions) t.id: t.fixedMovementId,
    }, containsPair('posted', 'rent'));
    expect(transactions.where((t) => t.fixedMovementId == null), hasLength(1));
  });

  test('v4 → v5 conserva los movimientos y agrega apartados', () async {
    final file = File('${dir.path}/db.sqlite');
    final v4 = open(file);
    await DriftTransactionRepository(v4)
        .save(expense(5000, category: 'seed-expense-food'));
    await downgradeToV4(v4);
    await v4.close();

    final v5 = open(file);
    addTearDown(v5.close);
    final transactions = await DriftTransactionRepository(v5)
        .getRecent(limit: 5);
    expect(transactions.single.provisionId, equals(null));
    expect(
      (await DriftCategoryRepository(v5).getAll(includeArchived: true))
          .map((c) => c.id),
      contains(DefaultCategories.provisions.id),
    );
    final provisions = DriftProvisionRepository(v5);
    final soat = Provision(
      id: 'soat',
      name: 'SOAT',
      amount: const Money.pesos(447000),
      everyMonths: 12,
      nextDue: DateTime(2026, 11),
      categoryId: 'seed-expense-transport',
    );
    await provisions.save(soat);
    expect(await provisions.getAll(), [soat]);
  });

  test('v2 → v3 agrega minuto del recordatorio, avisos y Mercado', () async {
    final file = File('${dir.path}/db.sqlite');
    final v2 = open(file);
    await DriftSettingsRepository(v2)
        .save(const FinanceSettings(payday: 15, reminderHour: 17));
    await downgradeToV2(v2);
    await v2.close();

    final v3 = open(file);
    addTearDown(v3.close);
    final settings = await DriftSettingsRepository(v3).get();
    expect(settings.payday, 15);
    expect(settings.reminderHour, 17);
    expect(settings.reminderMinute, 0);
    expect(settings.smartNotifications, isTrue);
    expect(
      (await DriftCategoryRepository(v3).getAll()).map((c) => c.id),
      contains(DefaultCategories.groceries.id),
    );
  });

  test('v1 → v3 conserva los datos y agrega fijos, día de pago y '
      'recordatorio', () async {
    final file = File('${dir.path}/db.sqlite');

    // Construye una base "v1": crea la actual y quita lo que agregó v2.
    final v1 = open(file);
    await DriftTransactionRepository(v1)
        .save(expense(5000, category: 'seed-expense-food'));
    await DriftSettingsRepository(v1)
        .save(const FinanceSettings(savingsTargetRate: Percentage.whole(15)));
    await downgradeToV2(v1);
    await v1.customStatement('DROP TABLE fixed_movements');
    for (final column in ['payday', 'daily_reminder', 'reminder_hour']) {
      await v1.customStatement(
        'ALTER TABLE finance_settings DROP COLUMN $column',
      );
    }
    await v1.customStatement(
      "DELETE FROM categories WHERE id = '${DefaultCategories.sports.id}'",
    );
    await v1.customStatement('PRAGMA user_version = 1');
    await v1.close();

    final v2 = open(file);
    addTearDown(v2.close);

    expect(
      await DriftTransactionRepository(v2).getRecent(limit: 5),
      hasLength(1),
    );
    final settings = await DriftSettingsRepository(v2).get();
    expect(settings.savingsTargetRate, const Percentage.whole(15));
    expect(settings.payday, FinanceSettings.defaultPayday);
    expect(settings.dailyReminder, isTrue);
    expect(settings.reminderHour, FinanceSettings.defaultReminderHour);
    expect(
      (await DriftCategoryRepository(v2).getAll()).map((c) => c.id),
      contains(DefaultCategories.sports.id),
    );

    final fixed = DriftFixedMovementRepository(v2);
    const rent = FixedMovement(
      id: 'rent',
      name: 'Arriendo',
      kind: TransactionKind.expense,
      amount: Money.pesos(1200000),
      categoryId: 'seed-expense-housing',
      dayOfMonth: 1,
    );
    await fixed.save(rent);
    expect(await fixed.getAll(), [rent]);
  });
}
