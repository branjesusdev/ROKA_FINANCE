/// Texto reconocido. Llega varias veces (parcial) y termina con
/// `isFinal = true`.
final class SpeechChunk {
  const new({required this.text, required this.isFinal});

  final String text;
  final bool isFinal;
}

enum SpeechUnavailableReason {
  /// El usuario negó el micrófono o el equipo no tiene reconocedor.
  notAvailable,

  /// Falta el paquete de español sin conexión (la voz nunca sale del
  /// teléfono).
  offlineLanguageMissing,

  /// No se entendió nada.
  noMatch,
}

final class SpeechUnavailable implements Exception {
  const new(this.reason, {this.code});

  final SpeechUnavailableReason reason;

  /// Código técnico del reconocedor (para diagnosticar en cada teléfono).
  final String? code;
}

/// Port de dictado por voz, reconocido en el dispositivo.
abstract interface class SpeechInput {
  /// Escucha una frase. El stream termina tras el resultado final o con un
  /// error [SpeechUnavailable].
  Stream<SpeechChunk> listen();

  Future<void> stop();

  /// Respaldo: abre la ventana de dictado de Google (la misma del teclado),
  /// que usa el español sin conexión si está descargado. Devuelve el texto
  /// o `null` si se canceló. Lanza [SpeechUnavailable] si no existe.
  Future<String?> listenWithSystemDialog();

  /// Resumen técnico de los reconocedores de voz del teléfono (sin datos
  /// personales), para diagnosticar fallas en cada marca.
  Future<String> diagnostics();
}
