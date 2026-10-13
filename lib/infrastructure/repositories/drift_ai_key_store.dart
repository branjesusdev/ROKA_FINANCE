import 'package:drift/drift.dart';
import 'package:finance_app/application/advisor/ai_ports.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/persistence/drift/tables.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

/// La llave vive en la base privada de la app (solo esta app puede leerla).
/// No está en el código ni en el APK, y `DriftBackupStore` no la exporta.
final class DriftAiKeyStore implements AiKeyStore {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<String?> read() => guardStorage(
    'aiKey.read',
    () async => (await _row().getSingleOrNull())?.apiKey,
  );

  @override
  Future<void> save(String? key) => guardStorage('aiKey.save', () async {
    final clean = key?.trim();
    if (clean == null || clean.isEmpty) {
      await _db.delete(_db.aiSecrets).go();
      return;
    }
    await _db
        .into(_db.aiSecrets)
        .insertOnConflictUpdate(
          AiSecretsCompanion.insert(
            id: const Value(AiSecrets.singletonId),
            apiKey: clean,
          ),
        );
  });

  @override
  Stream<bool> watchHasKey() => guardStorageStream(
    'aiKey.watch',
    _row().watchSingleOrNull().map((row) => row != null),
  );

  SimpleSelectStatement<$AiSecretsTable, AiSecretRow> _row() =>
      _db.select(_db.aiSecrets)
        ..where((s) => s.id.equals(AiSecrets.singletonId));
}
