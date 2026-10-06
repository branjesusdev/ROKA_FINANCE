import 'package:drift/drift.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';
import 'package:finance_app/infrastructure/mappers/settings_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/persistence/drift/tables.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftSettingsRepository implements SettingsRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<FinanceSettings> get() => guardStorage(
    'settings.get',
    () async => _toDomain(await _singleton().getSingleOrNull()),
  );

  @override
  Future<void> save(FinanceSettings settings) => guardStorage(
    'settings.save',
    () => _db
        .into(_db.financeSettingsTable)
        .insertOnConflictUpdate(settings.toCompanion()),
  );

  @override
  Stream<FinanceSettings> watch() => guardStorageStream(
    'settings.watch',
    _singleton().watchSingleOrNull().map(_toDomain),
  );

  SimpleSelectStatement<$FinanceSettingsTableTable, SettingsRow> _singleton() =>
      _db.select(_db.financeSettingsTable)
        ..where((s) => s.id.equals(FinanceSettingsTable.singletonId));

  FinanceSettings _toDomain(SettingsRow? row) =>
      row?.toDomain() ?? const FinanceSettings();
}
