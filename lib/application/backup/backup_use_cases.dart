import 'package:finance_app/application/backup/backup_ports.dart';
import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/shared/clock.dart';

/// Guarda una copia completa en un archivo que elige el usuario.
/// `Ok(false)` = canceló.
final class ExportBackup {
  const new({required this._store, required this._files, required this._clock});

  final BackupStore _store;
  final BackupFiles _files;
  final Clock _clock;

  static const filePrefix = 'finanzas-copia';

  Future<Result<bool>> call() => guardUseCase(() async {
    final now = _clock.now();
    final content = await _store.export(exportedAt: now);
    return await _files.save(fileName: fileName(now), content: content);
  });

  static String fileName(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$filePrefix-${date.year}-${two(date.month)}-${two(date.day)}'
        '.json';
  }
}

/// Carga una copia y agrega lo que falte. `Ok(null)` = canceló.
final class ImportBackup {
  const new({required this._store, required this._files});

  final BackupStore _store;
  final BackupFiles _files;

  Future<Result<BackupImportReport?>> call() async {
    try {
      return await guardUseCase(() async {
        final content = await _files.open();
        if (content == null) return null;
        return await _store.import(content);
      });
    } on InvalidBackupException catch (error) {
      return Err(
        ValidationFailure(
          error.newerVersion
              ? ValidationCodes.backupFromNewerVersion
              : ValidationCodes.backupInvalid,
        ),
      );
    }
  }
}
