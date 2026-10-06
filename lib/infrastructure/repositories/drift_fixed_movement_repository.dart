import 'package:drift/drift.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_repository.dart';
import 'package:finance_app/infrastructure/mappers/fixed_movement_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftFixedMovementRepository implements FixedMovementRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(FixedMovement movement) => guardStorage(
    'fixed.save',
    () => _db
        .into(_db.fixedMovements)
        .insertOnConflictUpdate(movement.toCompanion()),
  );

  @override
  Future<void> delete(String id) => guardStorage(
    'fixed.delete',
    () => (_db.delete(_db.fixedMovements)..where((f) => f.id.equals(id))).go(),
  );

  @override
  Future<List<FixedMovement>> getAll() => guardStorage(
    'fixed.getAll',
    () async => _toDomain(await _ordered().get()),
  );

  @override
  Stream<List<FixedMovement>> watchAll() =>
      guardStorageStream('fixed.watchAll', _ordered().watch().map(_toDomain));

  SimpleSelectStatement<$FixedMovementsTable, FixedMovementRow> _ordered() =>
      _db.select(_db.fixedMovements)..orderBy([
        (f) => OrderingTerm.asc(f.dayOfMonth),
        (f) => OrderingTerm.asc(f.name),
      ]);

  List<FixedMovement> _toDomain(List<FixedMovementRow> rows) =>
      rows.map((row) => row.toDomain()).toList();
}
