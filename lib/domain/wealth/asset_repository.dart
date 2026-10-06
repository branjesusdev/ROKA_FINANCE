import 'package:finance_app/domain/wealth/asset.dart';

abstract interface class AssetRepository {
  Future<void> save(Asset asset);

  Future<void> delete(String id);

  Future<List<Asset>> getAll();

  Stream<List<Asset>> watchAll();
}
