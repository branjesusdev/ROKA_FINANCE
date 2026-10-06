import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/drift_category_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_fixed_movement_repository.dart';
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

  test('v1 → v2 conserva los datos y agrega fijos, día de pago y '
      'recordatorio', () async {
    final file = File('${dir.path}/db.sqlite');

    // Construye una base "v1": crea la actual y quita lo que agregó v2.
    final v1 = open(file);
    await DriftTransactionRepository(v1)
        .save(expense(5000, category: 'seed-expense-food'));
    await DriftSettingsRepository(v1)
        .save(const FinanceSettings(savingsTargetRate: Percentage.whole(15)));
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
