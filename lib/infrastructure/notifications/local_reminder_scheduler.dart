import 'package:finance_app/application/reminders/reminder_scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Recordatorio diario con notificaciones locales (sin servidor). Usa
/// alarmas inexactas: no requiere el permiso de alarmas exactas y puede
/// llegar unos minutos tarde.
final class LocalReminderScheduler implements ReminderScheduler {
  new();

  static const _dailyId = 1;
  static const _channelId = 'daily_reminder';
  static const _icon = '@mipmap/ic_launcher';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
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
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> scheduleDaily({required int hour}) async {
    await _init();
    await _plugin.zonedSchedule(
      id: _dailyId,
      title: '¿Cómo te fue hoy?',
      body: 'Registra tus gastos e ingresos del día. Toma menos de un minuto.',
      scheduledDate: _nextInstanceOf(hour),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Recordatorio diario',
          channelDescription: 'Aviso para registrar los movimientos del día',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelDaily() async {
    await _init();
    await _plugin.cancel(id: _dailyId);
  }

  tz.TZDateTime _nextInstanceOf(int hour) {
    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }
}
