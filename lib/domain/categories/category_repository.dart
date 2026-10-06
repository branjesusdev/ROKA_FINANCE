import 'package:finance_app/domain/categories/category.dart';

/// Port de categorías. Las implementaciones lanzan `StorageException` ante
/// fallos de almacenamiento.
abstract interface class CategoryRepository {
  Future<void> save(Category category);

  Future<Category?> getById(String id);

  /// Ordenadas por tipo y `sortOrder`.
  Future<List<Category>> getAll({bool includeArchived = false});

  Stream<List<Category>> watchAll({bool includeArchived = false});
}
