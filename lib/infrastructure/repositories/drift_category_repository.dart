import 'package:drift/drift.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/categories/category_repository.dart';
import 'package:finance_app/infrastructure/mappers/category_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftCategoryRepository implements CategoryRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(Category category) => guardStorage(
    'categories.save',
    () =>
        _db.into(_db.categories).insertOnConflictUpdate(category.toCompanion()),
  );

  @override
  Future<Category?> getById(String id) =>
      guardStorage('categories.getById', () async {
        final query = _db.select(_db.categories)..where((c) => c.id.equals(id));
        return (await query.getSingleOrNull())?.toDomain();
      });

  @override
  Future<List<Category>> getAll({bool includeArchived = false}) => guardStorage(
    'categories.getAll',
    () async => _toDomain(await _all(includeArchived: includeArchived).get()),
  );

  @override
  Stream<List<Category>> watchAll({bool includeArchived = false}) =>
      guardStorageStream(
        'categories.watchAll',
        _all(includeArchived: includeArchived).watch().map(_toDomain),
      );

  SimpleSelectStatement<$CategoriesTable, CategoryRow> _all({
    required bool includeArchived,
  }) {
    final query = _db.select(_db.categories)
      ..orderBy([
        (c) => OrderingTerm.asc(c.kind),
        (c) => OrderingTerm.asc(c.sortOrder),
        (c) => OrderingTerm.asc(c.name),
      ]);
    if (!includeArchived) query.where((c) => c.isArchived.equals(false));
    return query;
  }

  List<Category> _toDomain(List<CategoryRow> rows) =>
      rows.map((row) => row.toDomain()).toList();
}
