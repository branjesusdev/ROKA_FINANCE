/// Por qué no respondió el proveedor de IA (la UI lo explica en simple).
enum AiFailureReason {
  /// No hay llave guardada.
  missingKey,

  /// La llave no sirve o fue revocada.
  unauthorized,

  /// Demasiadas consultas: esperar un rato.
  rateLimited,

  /// Sin internet o el servicio no respondió.
  network,

  /// Respondió algo que no se pudo leer.
  invalidResponse,
}

final class AiAdvisorException implements Exception {
  const new(this.reason);

  final AiFailureReason reason;

  @override
  String toString() => 'AiAdvisorException($reason)';
}

/// Port: modelo de lenguaje remoto. Solo recibe el texto que la app arma
/// (un resumen agregado que el usuario puede ver antes de enviar); nunca
/// accede a la base de datos.
abstract interface class AiAdvisor {
  /// Lanza [AiAdvisorException].
  Future<String> complete({
    required String apiKey,
    required String system,
    required String prompt,
    bool json = false,
  });
}

/// Port: dónde vive la llave del proveedor. Solo en el teléfono: no va en
/// la copia de seguridad ni en los logs.
abstract interface class AiKeyStore {
  Future<String?> read();

  /// `null` o vacío = borrarla.
  Future<void> save(String? key);

  Stream<bool> watchHasKey();
}
