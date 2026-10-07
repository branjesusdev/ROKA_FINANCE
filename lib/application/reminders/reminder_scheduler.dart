/// Canal del aviso: el usuario puede silenciar cada uno desde el teléfono.
enum ReminderChannel {
  /// Recordatorio diario para registrar movimientos.
  daily,

  /// Tope del día, fijos de mañana, día de pago, cierre de ciclo.
  smart,
}

/// Aviso local programado. [at] es hora local de pared.
final class Reminder {
  const new({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    this.channel = ReminderChannel.smart,
    this.repeatsDaily = false,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final ReminderChannel channel;

  /// Se repite todos los días a la misma hora (aunque no abras la app).
  final bool repeatsDaily;
}

/// Estado del sistema para explicar por qué no llegan los avisos.
final class ReminderDiagnostics {
  const new({
    required this.notificationsEnabled,
    required this.exactAlarms,
    required this.pending,
  });

  final bool notificationsEnabled;

  /// `false`: el sistema puede retrasar los avisos (ahorro de batería).
  final bool exactAlarms;

  /// Avisos programados ahora mismo.
  final int pending;
}

/// Port de avisos locales del sistema operativo (sin servidor).
abstract interface class ReminderScheduler {
  /// Pide permiso para notificar. `true` si quedó concedido.
  Future<bool> requestPermission();

  /// Reemplaza todos los avisos programados por [reminders].
  Future<void> replaceAll(List<Reminder> reminders);

  /// Agrega un aviso sin tocar los demás (p. ej. prueba en un minuto).
  Future<void> add(Reminder reminder);

  /// Muestra un aviso ya mismo (prueba).
  Future<void> showNow(Reminder reminder);

  Future<ReminderDiagnostics> diagnostics();
}
