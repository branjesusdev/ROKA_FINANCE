import 'package:finance_app/application/reminders/reminder_scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Avisos con notificaciones locales (sin servidor).
///
/// Usa alarmas exactas cuando el sistema lo permite (`USE_EXACT_ALARM` en
/// Android 13+, `SCHEDULE_EXACT_ALARM` en 12): las inexactas pueden
/// retrasarse horas o no llegar con el ahorro de batería. Si no hay
/// permiso, programa inexactas como respaldo.
final class LocalReminderScheduler implements ReminderScheduler {
  new();

  static const _icon = 'ic_notification';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Exception {
      // Zona desconocida: se queda en UTC y se corrige con el desfase.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
    );
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _android;
    if (android == null) return false;
    if (await android.areNotificationsEnabled() ?? false) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> replaceAll(List<Reminder> reminders) async {
    await _init();
    await _plugin.cancelAll();
    final mode = await _scheduleMode();
    for (final reminder in reminders) {
      await _schedule(reminder, mode);
    }
  }

  @override
  Future<void> add(Reminder reminder) async {
    await _init();
    await _schedule(reminder, await _scheduleMode());
  }

  @override
  Future<void> showNow(Reminder reminder) async {
    await _init();
    await _plugin.show(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      notificationDetails: _details(reminder),
    );
  }

  @override
  Future<ReminderDiagnostics> diagnostics() async {
    await _init();
    final android = _android;
    return ReminderDiagnostics(
      notificationsEnabled: await android?.areNotificationsEnabled() ?? false,
      exactAlarms: await android?.canScheduleExactNotifications() ?? false,
      pending: (await _plugin.pendingNotificationRequests()).length,
    );
  }

  Future<AndroidScheduleMode> _scheduleMode() async =>
      await _android?.canScheduleExactNotifications() ?? false
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  Future<void> _schedule(Reminder reminder, AndroidScheduleMode mode) =>
      _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: _toZoned(reminder.at),
        notificationDetails: _details(reminder),
        androidScheduleMode: mode,
        matchDateTimeComponents: reminder.repeatsDaily
            ? DateTimeComponents.time
            : null,
      );

  /// Hora de pared local → instante en la zona del teléfono.
  tz.TZDateTime _toZoned(DateTime at) =>
      tz.TZDateTime(tz.local, at.year, at.month, at.day, at.hour, at.minute);

  NotificationDetails _details(Reminder reminder) {
    final (id, name, description, importance) = switch (reminder.channel) {
      ReminderChannel.daily => (
        'daily_reminder_v2',
        'Recordatorio diario',
        'Aviso para registrar los movimientos del día',
        Importance.high,
      ),
      ReminderChannel.smart => (
        'smart_tips',
        'Tope del día y consejos',
        'Tope diario, fijos de mañana, día de pago y cierre de ciclo',
        Importance.defaultImportance,
      ),
    };
    return NotificationDetails(
      android: AndroidNotificationDetails(
        id,
        name,
        channelDescription: description,
        importance: importance,
        priority: importance == Importance.high
            ? Priority.high
            : Priority.defaultPriority,
        // En la pantalla bloqueada no se muestran montos.
        visibility: NotificationVisibility.private,
        styleInformation: BigTextStyleInformation(reminder.body),
        category: AndroidNotificationCategory.reminder,
      ),
    );
  }
}
