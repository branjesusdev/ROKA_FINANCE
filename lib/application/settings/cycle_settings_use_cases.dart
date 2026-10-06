import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';

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

/// Activa/desactiva el recordatorio diario y fija su hora.
final class UpdateDailyReminder {
  const new(this._settings);

  static const _hoursPerDay = 24;

  final SettingsRepository _settings;

  Future<Result<FinanceSettings>> call({required bool enabled, int? hour}) {
    if (hour != null && (hour < 0 || hour >= _hoursPerDay)) {
      return invalid(ValidationCodes.hourOutOfRange);
    }
    return guardUseCase(() async {
      final updated = (await _settings.get()).copyWith(
        dailyReminder: enabled,
        reminderHour: hour,
      );
      await _settings.save(updated);
      return updated;
    });
  }
}
