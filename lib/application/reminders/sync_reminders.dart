import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/reminders/reminder_planner.dart';
import 'package:finance_app/application/reminders/reminder_scheduler.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';

/// Alinea los avisos del sistema con la configuración y el ciclo actual. Se
/// llama al abrir la app, al volver a ella y cuando cambian los datos.
final class SyncReminders {
  const new({
    required this._settings,
    required this._scheduler,
    required this._clock,
  });

  final SettingsRepository _settings;
  final ReminderScheduler _scheduler;
  final Clock _clock;

  /// `false` si el sistema no permitió notificar. Nunca lanza: un fallo de
  /// los avisos no debe impedir usar la app.
  Future<bool> call({CycleSummary? summary}) async {
    try {
      final settings = await _settings.get();
      final reminders = const ReminderPlanner().plan(
        settings: settings,
        now: _clock.now(),
        summary: summary,
      );
      // Sin permiso el sistema simplemente no muestra los avisos.
      final granted = reminders.isEmpty || await _scheduler.requestPermission();
      await _scheduler.replaceAll(reminders);
      return granted;
    } on Exception {
      return false;
    }
  }
}

/// Avisos de prueba para comprobar que el teléfono los deja pasar.
final class TestReminder {
  const new({required this._scheduler, required this._clock});

  final ReminderScheduler _scheduler;
  final Clock _clock;

  static const _delay = Duration(minutes: 1);

  /// Muestra uno ya y programa otro en un minuto. `false` sin permiso.
  Future<bool> call() async {
    try {
      if (!await _scheduler.requestPermission()) return false;
      final now = _clock.now();
      await _scheduler.showNow(
        Reminder(
          id: ReminderPlanner.testId,
          at: now,
          title: 'Así se ven tus avisos',
          body: 'En un minuto llega otro programado.',
        ),
      );
      await _scheduler.add(
        Reminder(
          id: ReminderPlanner.testId + 1,
          at: now.add(_delay),
          title: 'Aviso programado: funciona',
          body: 'Si este llegó a tiempo, los recordatorios también llegarán.',
        ),
      );
      return true;
    } on Exception {
      return false;
    }
  }
}
