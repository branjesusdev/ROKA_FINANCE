import 'package:drift/drift.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/persistence/drift/tables.dart';

extension SettingsRowMapper on SettingsRow {
  FinanceSettings toDomain() => FinanceSettings(
    savingsTargetRate: Percentage.basisPoints(savingsTargetBasisPoints),
    thresholds: TrafficLightThresholds(
      warningFrom: Percentage.basisPoints(warningFromBasisPoints),
      criticalAbove: Percentage.basisPoints(criticalAboveBasisPoints),
    ),
    smallExpenseThreshold: Money(smallExpenseThresholdCents),
    payday: payday,
    dailyReminder: dailyReminder,
    reminderHour: reminderHour,
    reminderMinute: reminderMinute,
    smartNotifications: smartNotifications,
    dependents: dependents,
    soloProvider: soloProvider,
    kidsMonthlyBuffer: Money(kidsMonthlyBufferCents),
    appearance: appearance,
  );
}

extension SettingsCompanionMapper on FinanceSettings {
  FinanceSettingsTableCompanion toCompanion() =>
      FinanceSettingsTableCompanion.insert(
        id: const Value(FinanceSettingsTable.singletonId),
        savingsTargetBasisPoints: savingsTargetRate.basisPoints,
        warningFromBasisPoints: thresholds.warningFrom.basisPoints,
        criticalAboveBasisPoints: thresholds.criticalAbove.basisPoints,
        smallExpenseThresholdCents: smallExpenseThreshold.cents,
        payday: Value(payday),
        dailyReminder: Value(dailyReminder),
        reminderHour: Value(reminderHour),
        reminderMinute: Value(reminderMinute),
        smartNotifications: Value(smartNotifications),
        dependents: Value(dependents),
        soloProvider: Value(soloProvider),
        kidsMonthlyBufferCents: Value(kidsMonthlyBuffer.cents),
        appearance: Value(appearance),
      );
}
