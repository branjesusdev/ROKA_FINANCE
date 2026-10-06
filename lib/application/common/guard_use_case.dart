import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/core/storage_exception.dart';

/// Convierte fallos de almacenamiento en `Err(StorageFailure)`.
Future<Result<T>> guardUseCase<T>(Future<T> Function() action) async {
  try {
    return Ok(await action());
  } on StorageException catch (error) {
    return Err(StorageFailure(error.operation));
  }
}
