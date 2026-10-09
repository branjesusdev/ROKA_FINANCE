import 'package:finance_app/application/backup/backup_ports.dart';
import 'package:finance_app/core/storage_exception.dart';
import 'package:flutter/services.dart';

/// Guardar/abrir con el selector de archivos de Android (Descargas, Drive,
/// WhatsApp…). El archivo solo va donde el usuario elija.
final class AndroidBackupFiles implements BackupFiles {
  const new();

  static const _channel = MethodChannel('finance_app/backup');

  @override
  Future<bool> save({required String fileName, required String content}) =>
      _guard(
        'backup.save',
        () async =>
            await _channel.invokeMethod<bool>('save', {
              'fileName': fileName,
              'content': content,
            }) ??
            false,
      );

  @override
  Future<String?> open() =>
      _guard('backup.open', () => _channel.invokeMethod<String>('open'));

  Future<T> _guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageException(operation, cause: error),
        stackTrace,
      );
    }
  }
}
