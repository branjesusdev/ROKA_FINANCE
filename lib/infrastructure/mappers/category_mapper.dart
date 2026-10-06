import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';

extension CategoryRowMapper on CategoryRow {
  Category toDomain() => Category(
    id: id,
    name: name,
    kind: kind,
    iconKey: iconKey,
    sortOrder: sortOrder,
    isArchived: isArchived,
    countsAsSaving: countsAsSaving,
  );
}

extension CategoryCompanionMapper on Category {
  CategoriesCompanion toCompanion() => CategoriesCompanion.insert(
    id: id,
    name: name,
    kind: kind,
    iconKey: iconKey,
    sortOrder: sortOrder,
    isArchived: isArchived,
    countsAsSaving: countsAsSaving,
  );
}
