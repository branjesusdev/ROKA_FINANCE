import 'package:finance_app/application/backup/backup_ports.dart';
import 'package:finance_app/application/reminders/reminder_scheduler.dart';
import 'package:finance_app/application/voice/speech_input.dart';
import 'package:finance_app/domain/accounts/account_repository.dart';
import 'package:finance_app/domain/budgets/budget_repository.dart';
import 'package:finance_app/domain/categories/category_repository.dart';
import 'package:finance_app/domain/debts/debt_repository.dart';
import 'package:finance_app/domain/fixed/fixed_movement_repository.dart';
import 'package:finance_app/domain/investments/investment_repository.dart';
import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/provisions/provision_repository.dart';
import 'package:finance_app/domain/savings/savings_goal_repository.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';
import 'package:finance_app/domain/wealth/asset_repository.dart';
import 'package:finance_app/infrastructure/backup/android_backup_files.dart';
import 'package:finance_app/infrastructure/backup/drift_backup_store.dart';
import 'package:finance_app/infrastructure/markets/yahoo_market_data_source.dart';
import 'package:finance_app/infrastructure/notifications/local_reminder_scheduler.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/drift_account_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_asset_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_budget_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_category_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_debt_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_fixed_movement_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_investment_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_provision_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_savings_goal_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_settings_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:finance_app/infrastructure/speech/device_speech_input.dart';
import 'package:finance_app/infrastructure/system/system_clock.dart';
import 'package:finance_app/infrastructure/system/uuid_id_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Composition root: único lugar donde los ports se conectan con adapters
// concretos. Para cambiar a cloud, reemplazar aquí la implementación.
// En tests se sobrescribe `appDatabaseProvider` con una base en memoria.

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => const UuidIdGenerator(),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.open();
  ref.onDispose(database.close);
  return database;
});

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => DriftCategoryRepository(ref.watch(appDatabaseProvider)),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => DriftAccountRepository(ref.watch(appDatabaseProvider)),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => DriftTransactionRepository(ref.watch(appDatabaseProvider)),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => DriftBudgetRepository(ref.watch(appDatabaseProvider)),
);

final assetRepositoryProvider = Provider<AssetRepository>(
  (ref) => DriftAssetRepository(ref.watch(appDatabaseProvider)),
);

final debtRepositoryProvider = Provider<DebtRepository>(
  (ref) => DriftDebtRepository(ref.watch(appDatabaseProvider)),
);

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>(
  (ref) => DriftSavingsGoalRepository(ref.watch(appDatabaseProvider)),
);

final investmentRepositoryProvider = Provider<InvestmentRepository>(
  (ref) => DriftInvestmentRepository(ref.watch(appDatabaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider)),
);

final fixedMovementRepositoryProvider = Provider<FixedMovementRepository>(
  (ref) => DriftFixedMovementRepository(ref.watch(appDatabaseProvider)),
);

final provisionRepositoryProvider = Provider<ProvisionRepository>(
  (ref) => DriftProvisionRepository(ref.watch(appDatabaseProvider)),
);

/// Adapters de plataforma. En tests se sobrescriben con fakes.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalReminderScheduler(),
);

final speechInputProvider = Provider<SpeechInput>((ref) => DeviceSpeechInput());

/// Precios públicos de mercado (solo envía el símbolo consultado).
final marketDataSourceProvider = Provider<MarketDataSource>(
  (ref) => YahooMarketDataSource(),
);

final backupStoreProvider = Provider<BackupStore>(
  (ref) => DriftBackupStore(ref.watch(appDatabaseProvider)),
);

final backupFilesProvider = Provider<BackupFiles>(
  (ref) => const AndroidBackupFiles(),
);
