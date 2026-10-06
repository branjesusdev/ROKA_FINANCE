/// Fallo de infraestructura al leer o escribir datos.
///
/// Los adapters la lanzan en lugar de exponer excepciones del motor
/// (que pueden incluir SQL y valores). Los casos de uso la convierten en
/// `StorageFailure`. `toString` nunca incluye la causa.
final class StorageException implements Exception {
  const new(this.operation, {this.cause});

  final String operation;
  final Object? cause;

  @override
  String toString() => 'StorageException($operation)';
}
