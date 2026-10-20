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
    NetWorthSnapshots,
    AiReviews,
    AiSecrets,
  ],
)
class AppDatabase extends _$AppDatabase {
  new(super.e);

  /// Base de datos local en el almacenamiento privado de la app.
  factory open() => AppDatabase(driftDatabase(name: fileName));

  static const fileName = 'finance_app';

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seedDefaults();
    },
    onUpgrade: (migrator, from, to) async {
      // Primero: los pasos de abajo insertan categorías con todas las
      // columnas actuales.
      if (from < 9) {
        await migrator.addColumn(categories, categories.isExtraordinary);
      }
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
      if (from < 9) {
        for (final column in <GeneratedColumn<Object>>[
          assets.monthlyCostCents,
          assets.monthlyIncomeCents,
          assets.liquidity,
          assets.linkedDebtId,
        ]) {
          await migrator.addColumn(assets, column);
        }
        for (final column in <GeneratedColumn<Object>>[
          financeSettingsTable.aiEnabled,
          financeSettingsTable.aiReviewFrequency,
        ]) {
          await migrator.addColumn(financeSettingsTable, column);
        }
        await migrator.createTable(netWorthSnapshots);
        await migrator.createTable(aiReviews);
        await migrator.createTable(aiSecrets);
        await (update(categories)
              ..where((c) => c.id.equals(DefaultCategories.extraordinaryId)))
            .write(const CategoriesCompanion(isExtraordinary: Value(true)));
        for (final category in DefaultCategories.extraordinaryIncomes) {
          await into(categories)
              .insert(category.toCompanion(), mode: InsertMode.insertOrIgnore);
        }
      }
      if (from < 10) {
        for (final column in <GeneratedColumn<Object>>[
          investments.symbol,
          investments.unitsMicros,
          investments.priceUpdatedAt,
        ]) {
          await migrator.addColumn(investments, column);
        }
      }
      if (from < 11) {
        await migrator.addColumn(transactions, transactions.odometerKm);
        await migrator.addColumn(investments, investments.investedUsdCents);
        // Antes de v2 la tabla de fijos se creó completa, con la columna.
        if (from >= 2) {
          await migrator.addColumn(fixedMovements, fixedMovements.debtId);
        }
      }
      // Antes de v2 la tabla de fijos se creó completa, con la columna.
      if (from >= 2 && from < 12) {
        await migrator.addColumn(fixedMovements, fixedMovements.remindOn);
      }
      // Desde v13 los gastos fijos piden "Ya lo pagué" salvo los marcados
      // como débito automático.
      if (from >= 2 && from < 13) {
        await migrator.addColumn(fixedMovements, fixedMovements.autoDebit);
      }
      if (from < 14) {
        await migrator.addColumn(
          financeSettingsTable,
          financeSettingsTable.monthlySalaryCents,
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
