import 'package:drift/drift.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/domain/wealth/asset_repository.dart';
import 'package:finance_app/infrastructure/mappers/wealth_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftAssetRepository implements AssetRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(Asset asset) => guardStorage(
    'assets.save',
    () => _db.into(_db.assets).insertOnConflictUpdate(asset.toCompanion()),
  );

  @override
  Future<void> delete(String id) => guardStorage(
    'assets.delete',
    () => (_db.delete(_db.assets)..where((a) => a.id.equals(id))).go(),
  );

  @override
  Future<List<Asset>> getAll() =>
      guardStorage('assets.getAll', () async => _toDomain(await _all().get()));

  @override
  Stream<List<Asset>> watchAll() =>
      guardStorageStream('assets.watchAll', _all().watch().map(_toDomain));

  SimpleSelectStatement<$AssetsTable, AssetRow> _all() =>
      _db.select(_db.assets)..orderBy([(a) => OrderingTerm.asc(a.name)]);

  List<Asset> _toDomain(List<AssetRow> rows) =>
      rows.map((row) => row.toDomain()).toList();
}
