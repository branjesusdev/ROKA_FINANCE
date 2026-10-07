import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/drift_category_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_fixed_movement_repository.dart';
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

  /// Quita lo que agregó v5 a una base recién creada.
  Future<void> downgradeToV4(AppDatabase db) async {
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
