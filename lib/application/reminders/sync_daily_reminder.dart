import 'package:finance_app/application/reminders/reminder_scheduler.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';

/// Alinea el recordatorio del sistema con la configuración guardada. Se
/// llama al abrir la app y cada vez que cambia la configuración.
final class SyncDailyReminder {
  const new({required this._settings, required this._scheduler});

  final SettingsRepository _settings;
  final ReminderScheduler _scheduler;

  /// `false` si el sistema no permitió programarlo. Nunca lanza: un fallo
  /// del recordatorio no debe impedir usar la app.
  Future<bool> call() async {
    try {
      final settings = await _settings.get();
      if (!settings.dailyReminder) {
        await _scheduler.cancelDaily();
        return true;
      }
      // Sin permiso el sistema simplemente no muestra la notificación.
      final granted = await _scheduler.requestPermission();
      await _scheduler.scheduleDaily(hour: settings.reminderHour);
      return granted;
    } on Exception {
      return false;
    }
  }
}
