/// Errores esperados del negocio o de almacenamiento.
///
/// `message` es solo para diagnóstico: nunca incluir montos ni datos del
/// usuario.
sealed class Failure {
  const new(this.message);

  final String message;
}

final class ValidationFailure extends Failure {
  const new(super.message);
}

final class NotFoundFailure extends Failure {
  const new(super.message);
}

final class StorageFailure extends Failure {
  const new(super.message);
}
