import 'package:finance_app/application/backup/backup_ports.dart';
import 'package:finance_app/application/backup/backup_use_cases.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Clock implements Clock {
  @override
  DateTime now() => DateTime(2026, 10, 8, 14);
}

final class _Store implements BackupStore {
  Exception? importError;

  @override
  Future<String> export({required DateTime exportedAt}) async => '{}';

  @override
  Future<BackupImportReport> import(String content) async {
    if (importError case final error?) throw error;
    return const BackupImportReport(added: 1, skipped: 0, movementsAdded: 1);
  }
}

final class _Files implements BackupFiles {
  String? savedName;
  String? toOpen;
  bool accept = true;

  @override
  Future<bool> save({required String fileName, required String content}) async {
    savedName = fileName;
    return accept;
  }

  @override
  Future<String?> open() async => toOpen;
}

void main() {
  late _Store store;
  late _Files files;

  setUp(() {
    store = _Store();
    files = _Files();
  });

  test('exporta con la fecha en el nombre del archivo', () async {
    final result = await ExportBackup(
      store: store,
      files: files,
      clock: _Clock(),
    ).call();

    expect(result, isA<Ok<bool>>().having((r) => r.value, 'value', true));
    expect(files.savedName, 'finanzas-copia-2026-10-08.json');
  });

  test('cancelar la importación devuelve Ok(null)', () async {
    final result = await ImportBackup(store: store, files: files).call();

    expect(
      result,
      isA<Ok<BackupImportReport?>>().having((r) => r.value, 'value', isNull),
    );
  });

  test('archivo inválido o más nuevo se traduce a validación', () async {
    files.toOpen = 'x';
    store.importError = const InvalidBackupException(newerVersion: true);

    final result = await ImportBackup(store: store, files: files).call();

    expect(
      result,
      isA<Err<BackupImportReport?>>().having(
        (r) => r.failure,
        'failure',
        isA<ValidationFailure>().having(
          (f) => f.message,
          'code',
          ValidationCodes.backupFromNewerVersion,
        ),
      ),
    );
  });
}
