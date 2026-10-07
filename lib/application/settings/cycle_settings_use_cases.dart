import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';
import 'package:finance_app/domain/shared/money.dart';

/// Cambia el día de pago (inicio de cada ciclo).
final class UpdatePayday {
  const new(this._settings);

  final SettingsRepository _settings;

  Future<Result<FinanceSettings>> call(int payday) {
    if (payday < PayCycle.minPayday || payday > PayCycle.maxPayday) {
      return invalid(ValidationCodes.dayOutOfRange);
    }
    return guardUseCase(() async {
      final updated = (await _settings.get()).copyWith(payday: payday);
      await _settings.save(updated);
      return updated;
    });
  }
}

/// Activa/desactiva el recordatorio diario, fija su hora y minuto, y los
/// avisos inteligentes.
final class UpdateDailyReminder {
  const new(this._settings);

  static const _hoursPerDay = 24;
  static const _minutesPerHour = 60;

  final SettingsRepository _settings;

  Future<Result<FinanceSettings>> call({
    bool? enabled,
    int? hour,
    int? minute,
    bool? smartNotifications,
  }) {
    if (hour != null && (hour < 0 || hour >= _hoursPerDay)) {
      return invalid(ValidationCodes.hourOutOfRange);
    }
    if (minute != null && (minute < 0 || minute >= _minutesPerHour)) {
      return invalid(ValidationCodes.hourOutOfRange);
    }
    return guardUseCase(() async {
      final updated = (await _settings.get()).copyWith(
        dailyReminder: enabled,
        reminderHour: hour,
        reminderMinute: minute,
        smartNotifications: smartNotifications,
      );
      await _settings.save(updated);
      return updated;
    });
  }
}

/// Perfil del hogar: hijos a cargo, si eres el único ingreso y el apartado
/// mensual para imprevistos de los niños. Ajusta el tope diario, el fondo
/// de emergencia sugerido y el plan del sobrante.
final class UpdateHousehold {
  const new(this._settings);

  static const maxDependents = 10;

  final SettingsRepository _settings;

  Future<Result<FinanceSettings>> call({
    int? dependents,
    bool? soloProvider,
    Money? kidsMonthlyBuffer,
  }) {
    if (dependents != null && (dependents < 0 || dependents > maxDependents)) {
      return invalid(ValidationCodes.dayOutOfRange);
    }
    if (kidsMonthlyBuffer != null && kidsMonthlyBuffer.isNegative) {
      return invalid(ValidationCodes.amountMustNotBeNegative);
    }
    return guardUseCase(() async {
      final updated = (await _settings.get()).copyWith(
        dependents: dependents,
        soloProvider: soloProvider,
        kidsMonthlyBuffer: kidsMonthlyBuffer,
      );
      await _settings.save(updated);
      return updated;
    });
  }
}
