import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:meta/meta.dart';

/// Preferencias configurables por el usuario.
@immutable
final class FinanceSettings {
  const new({
    this.savingsTargetRate = defaultSavingsTargetRate,
    this.thresholds = const TrafficLightThresholds(),
    this.smallExpenseThreshold = defaultSmallExpenseThreshold,
    this.payday = defaultPayday,
    this.dailyReminder = true,
    this.reminderHour = defaultReminderHour,
  });

  /// Referencia (no obligación): 10% del ingreso.
  static const defaultSavingsTargetRate = Percentage.whole(10);
  static const defaultSmallExpenseThreshold = Money.pesos(20000);
  static const defaultPayday = 20;
  static const defaultReminderHour = 18;

  final Percentage savingsTargetRate;
  final TrafficLightThresholds thresholds;

  /// Gastos iguales o menores cuentan como "compra pequeña".
  final Money smallExpenseThreshold;

  /// Día del mes en que llega el sueldo: inicio de cada ciclo.
  final int payday;

  /// Recordatorio diario para registrar gastos e ingresos.
  final bool dailyReminder;

  /// Hora (0–23) del recordatorio.
  final int reminderHour;

  FinanceSettings copyWith({
    Percentage? savingsTargetRate,
    TrafficLightThresholds? thresholds,
    Money? smallExpenseThreshold,
    int? payday,
    bool? dailyReminder,
    int? reminderHour,
  }) => FinanceSettings(
    savingsTargetRate: savingsTargetRate ?? this.savingsTargetRate,
    thresholds: thresholds ?? this.thresholds,
    smallExpenseThreshold: smallExpenseThreshold ?? this.smallExpenseThreshold,
    payday: payday ?? this.payday,
    dailyReminder: dailyReminder ?? this.dailyReminder,
    reminderHour: reminderHour ?? this.reminderHour,
  );

  @override
  bool operator ==(Object other) =>
      other is FinanceSettings &&
      other.savingsTargetRate == savingsTargetRate &&
      other.thresholds == thresholds &&
      other.smallExpenseThreshold == smallExpenseThreshold &&
      other.payday == payday &&
      other.dailyReminder == dailyReminder &&
      other.reminderHour == reminderHour;

  @override
  int get hashCode => Object.hash(
    savingsTargetRate,
    thresholds,
    smallExpenseThreshold,
    payday,
    dailyReminder,
    reminderHour,
  );
}
