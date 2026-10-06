import 'package:finance_app/core/storage_exception.dart';

/// Ejecuta [action] traduciendo excepciones del motor a [StorageException]
/// (sin exponer SQL ni valores).
Future<T> guardStorage<T>(String operation, Future<T> Function() action) async {
  try {
    return await action();
  } on Exception catch (error, stackTrace) {
    Error.throwWithStackTrace(
      StorageException(operation, cause: error),
      stackTrace,
    );
  }
}

/// Igual que [guardStorage] para consultas observables.
Stream<T> guardStorageStream<T>(String operation, Stream<T> stream) =>
    stream.handleError(
      (Object error, StackTrace stackTrace) => Error.throwWithStackTrace(
        StorageException(operation, cause: error),
        stackTrace,
      ),
      test: (error) => error is Exception,
    );
