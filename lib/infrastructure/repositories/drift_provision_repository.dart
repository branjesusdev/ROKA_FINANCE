import 'package:drift/drift.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/provisions/provision_repository.dart';
import 'package:finance_app/infrastructure/mappers/provision_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftProvisionRepository implements ProvisionRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(Provision provision) => guardStorage(
    'provisions.save',
    () => _db
        .into(_db.provisions)
        .insertOnConflictUpdate(provision.toCompanion()),
  );

  @override
  Future<void> delete(String id) => guardStorage(
    'provisions.delete',
    () => _db.transaction(() async {
      await (_db.update(_db.transactions)
            ..where((t) => t.provisionId.equals(id)))
          .write(const TransactionsCompanion(provisionId: Value(null)));
      await (_db.delete(_db.provisions)..where((p) => p.id.equals(id))).go();
    }),
  );

  @override
  Future<Provision?> getById(String id) =>
      guardStorage('provisions.getById', () async {
        final query = _db.select(_db.provisions)..where((p) => p.id.equals(id));
        return (await query.getSingleOrNull())?.toDomain();
      });

  @override
  Future<List<Provision>> getAll() => guardStorage(
    'provisions.getAll',
    () async => _toDomain(await _ordered().get()),
  );

  @override
  Stream<List<Provision>> watchAll() => guardStorageStream(
    'provisions.watchAll',
    _ordered().watch().map(_toDomain),
  );

  SimpleSelectStatement<$ProvisionsTable, ProvisionRow> _ordered() =>
      _db.select(_db.provisions)..orderBy([
        (p) => OrderingTerm.asc(p.nextDue),
        (p) => OrderingTerm.asc(p.name),
      ]);

  List<Provision> _toDomain(List<ProvisionRow> rows) =>
      rows.map((row) => row.toDomain()).toList();
}
