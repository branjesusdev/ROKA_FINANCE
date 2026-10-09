import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
// Los imports de dominio son necesarios: el código generado referencia los
// enums de las columnas `textEnum`.
import 'package:finance_app/domain/accounts/account.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/infrastructure/mappers/account_mapper.dart';
import 'package:finance_app/infrastructure/mappers/category_mapper.dart';
import 'package:finance_app/infrastructure/mappers/settings_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    Accounts,
    Transactions,
    BudgetLines,
    Assets,
    Debts,
    ExtraPayments,
    SavingsGoals,
    GoalContributions,
    Investments,
    FinanceSettingsTable,
    FixedMovements,
    Provisions,
  ],
)
class AppDatabase extends _$AppDatabase {
  new(super.e);

  /// Base de datos local en el almacenamiento privado de la app.
  factory open() => AppDatabase(driftDatabase(name: fileName));

  static const fileName = 'finance_app';

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seedDefaults();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(fixedMovements);
        await migrator.addColumn(
          financeSettingsTable,
          financeSettingsTable.payday,
        );
        await migrator.addColumn(
          financeSettingsTable,
          financeSettingsTable.dailyReminder,
        );
        await migrator.addColumn(
          financeSettingsTable,
          financeSettingsTable.reminderHour,
        );
        await into(categories).insert(
          DefaultCategories.sports.toCompanion(),
          mode: InsertMode.insertOrIgnore,
        );
      }
      if (from < 3) {
        await migrator.addColumn(
          financeSettingsTable,
          financeSettingsTable.reminderMinute,
        );
        await migrator.addColumn(
          financeSettingsTable,
          financeSettingsTable.smartNotifications,
        );
        await into(categories).insert(
          DefaultCategories.groceries.toCompanion(),
          mode: InsertMode.insertOrIgnore,
        );
      }
      if (from < 4) {
        for (final column in [
          financeSettingsTable.dependents,
          financeSettingsTable.soloProvider,
          financeSettingsTable.kidsMonthlyBufferCents,
        ]) {
          await migrator.addColumn(financeSettingsTable, column);
        }
        for (final category in [
          DefaultCategories.untracked,
          DefaultCategories.balanceAdjustment,
        ]) {
          await into(categories)
              .insert(category.toCompanion(), mode: InsertMode.insertOrIgnore);
        }
      }
      if (from < 5) {
        await migrator.createTable(provisions);
        await migrator.addColumn(transactions, transactions.provisionId);
        await into(categories).insert(
          DefaultCategories.provisions.toCompanion(),
          mode: InsertMode.insertOrIgnore,
        );
      }
      if (from < 6) {
        await migrator.addColumn(transactions, transactions.fixedMovementId);
        // Los fijos ya registrados se reconocen por nombre, tipo, categoría
        // y monto (así los creaba PostDueFixedMovements).
        await customStatement('''
          UPDATE transactions SET fixed_movement_id = (
            SELECT f.id FROM fixed_movements f
            WHERE f.name = transactions.description
              AND f.kind = transactions.kind
              AND f.category_id = transactions.category_id
              AND f.amount_cents = transactions.amount_cents
            LIMIT 1
          )
          WHERE fixed_movement_id IS NULL
        ''');
      }
      // Antes de v2 la tabla se acaba de crear completa, con la columna.
      if (from >= 2 && from < 7) {
        await migrator.addColumn(fixedMovements, fixedMovements.isVariable);
      }
      if (from < 8) {
        await migrator.addColumn(
          financeSettingsTable,
          financeSettingsTable.appearance,
        );
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> _seedDefaults() => batch((batch) {
    batch
      ..insertAll(
        categories,
        DefaultCategories.all.map((category) => category.toCompanion()),
      )
      ..insert(accounts, Account.defaultCash.toCompanion())
      ..insert(financeSettingsTable, const FinanceSettings().toCompanion());
  });
}
