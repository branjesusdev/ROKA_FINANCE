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
  const new(this.reason);

  final SpeechUnavailableReason reason;
}

/// Port de dictado por voz, reconocido en el dispositivo.
abstract interface class SpeechInput {
  /// Escucha una frase. El stream termina tras el resultado final o con un
  /// error [SpeechUnavailable].
  Stream<SpeechChunk> listen();

  Future<void> stop();
}
