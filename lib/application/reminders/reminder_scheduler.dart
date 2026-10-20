/// Canal del aviso: el usuario puede silenciar cada uno desde el teléfono.
enum ReminderChannel {
  /// Recordatorio diario para registrar movimientos.
  daily,

  /// Tope del día, fijos de mañana, día de pago, cierre de ciclo.
  smart,
}

/// Botones de una factura por confirmar dentro de la notificación.
enum ReminderAction {
  /// ✓ Ya lo pagué: abre la app para escribir el valor.
  paid,

  /// Aún no: recuérdame mañana.
  tomorrow,

  /// Aún no: recuérdame en 2 días.
  inTwoDays,
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
    this.actions = const [],
    this.payload,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final ReminderChannel channel;

  /// Se repite todos los días a la misma hora (aunque no abras la app).
  final bool repeatsDaily;

  /// Botones del aviso (vacío = solo se toca para abrir la app).
  final List<ReminderAction> actions;

  /// Dato que vuelve al tocar el aviso (p. ej. el id del fijo).
  final String? payload;
}

/// El usuario tocó un aviso o uno de sus botones ([action] `null` = tocó
/// el aviso).
final class ReminderResponse {
  const new({required this.payload, this.action});

  final String? payload;
  final ReminderAction? action;
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

  /// Toques en avisos y en sus botones, incluido el que abrió la app.
  Stream<ReminderResponse> responses();
}
