/// Port de recordatorios locales del sistema operativo.
abstract interface class ReminderScheduler {
  /// Pide permiso para notificar. `true` si quedó concedido.
  Future<bool> requestPermission();

  /// Programa (o reprograma) el recordatorio diario a la [hour] indicada.
  Future<void> scheduleDaily({required int hour});

  Future<void> cancelDaily();
}
