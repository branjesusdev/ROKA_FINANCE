import 'package:finance_app/application/budgets/budget_use_cases.dart';
import 'package:finance_app/application/debts/debt_use_cases.dart';
import 'package:finance_app/application/fixed/fixed_movement_use_cases.dart';
import 'package:finance_app/application/reminders/sync_daily_reminder.dart';
import 'package:finance_app/application/savings/savings_use_cases.dart';
import 'package:finance_app/application/settings/cycle_settings_use_cases.dart';
import 'package:finance_app/application/transactions/delete_transaction.dart';
import 'package:finance_app/application/transactions/register_transaction.dart';
import 'package:finance_app/application/wealth/wealth_use_cases.dart';
import 'package:finance_app/bootstrap/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Casos de uso (escrituras). Las lecturas observan los ports directamente
// desde presentation/shared/data_providers.dart.

final registerTransactionProvider = Provider(
  (ref) => RegisterTransaction(
    transactions: ref.watch(transactionRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final deleteTransactionProvider = Provider(
  (ref) => DeleteTransaction(ref.watch(transactionRepositoryProvider)),
);

final setBudgetLimitProvider = Provider(
  (ref) => SetBudgetLimit(
    budgets: ref.watch(budgetRepositoryProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final removeBudgetLimitProvider = Provider(
  (ref) => RemoveBudgetLimit(ref.watch(budgetRepositoryProvider)),
);

final copyPreviousMonthBudgetProvider = Provider(
  (ref) => CopyPreviousMonthBudget(
    budgets: ref.watch(budgetRepositoryProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final saveAssetProvider = Provider(
  (ref) => SaveAsset(
    assets: ref.watch(assetRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final deleteAssetProvider = Provider(
  (ref) => DeleteAsset(ref.watch(assetRepositoryProvider)),
);

final saveInvestmentProvider = Provider(
  (ref) => SaveInvestment(
    investments: ref.watch(investmentRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final deleteInvestmentProvider = Provider(
  (ref) => DeleteInvestment(ref.watch(investmentRepositoryProvider)),
);

final saveDebtProvider = Provider(
  (ref) => SaveDebt(
    debts: ref.watch(debtRepositoryProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final deleteDebtProvider = Provider(
  (ref) => DeleteDebt(ref.watch(debtRepositoryProvider)),
);

final registerDebtPaymentProvider = Provider(
  (ref) => RegisterDebtPayment(
    debts: ref.watch(debtRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final registerExtraPaymentProvider = Provider(
  (ref) => RegisterExtraPayment(
    debts: ref.watch(debtRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final updateSavingsTargetProvider = Provider(
  (ref) => UpdateSavingsTarget(ref.watch(settingsRepositoryProvider)),
);

final saveGoalProvider = Provider(
  (ref) => SaveGoal(
    goals: ref.watch(savingsGoalRepositoryProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final deleteGoalProvider = Provider(
  (ref) => DeleteGoal(ref.watch(savingsGoalRepositoryProvider)),
);

final addContributionProvider = Provider(
  (ref) => AddContribution(
    goals: ref.watch(savingsGoalRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final saveFixedMovementProvider = Provider(
  (ref) => SaveFixedMovement(
    fixed: ref.watch(fixedMovementRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final deleteFixedMovementProvider = Provider(
  (ref) => DeleteFixedMovement(ref.watch(fixedMovementRepositoryProvider)),
);

final postDueFixedMovementsProvider = Provider(
  (ref) => PostDueFixedMovements(
    fixed: ref.watch(fixedMovementRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final updatePaydayProvider = Provider(
  (ref) => UpdatePayday(ref.watch(settingsRepositoryProvider)),
);

final updateDailyReminderProvider = Provider(
  (ref) => UpdateDailyReminder(ref.watch(settingsRepositoryProvider)),
);

final syncDailyReminderProvider = Provider(
  (ref) => SyncDailyReminder(
    settings: ref.watch(settingsRepositoryProvider),
    scheduler: ref.watch(reminderSchedulerProvider),
  ),
);
