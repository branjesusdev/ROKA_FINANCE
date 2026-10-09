import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/categories/category_repository.dart';
import 'package:finance_app/domain/shared/id_generator.dart';

/// Crea una categoría propia al final de su lista. No permite dos activas
/// con el mismo nombre (sin importar mayúsculas) en el mismo tipo; si
/// existe una oculta con ese nombre, la vuelve a mostrar (conserva sus
/// movimientos).
final class CreateCategory {
  const new({required this._categories, required this._ids});

  final CategoryRepository _categories;
  final IdGenerator _ids;

  Future<Result<Category>> call({
    required String name,
    required CategoryKind kind,
    required String iconKey,
    bool countsAsSaving = false,
  }) async {
    final cleanName = cleanText(name);
    if (cleanName == null) return await invalid(ValidationCodes.nameRequired);
    final saved = await guardUseCase<Category?>(() async {
      final sameKind = (await _categories.getAll(includeArchived: true))
          .where((c) => c.kind == kind)
          .toList();
      final twins = sameKind.where((c) => _sameName(c.name, cleanName));
      if (twins.any((c) => !c.isArchived)) return null;
      final category =
          twins.firstOrNull?.copyWith(isArchived: false, iconKey: iconKey) ??
          Category(
            id: _ids.next(),
            name: cleanName,
            kind: kind,
            iconKey: iconKey,
            sortOrder: _nextOrder(sameKind),
            countsAsSaving: countsAsSaving,
          );
      await _categories.save(category);
      return category;
    });
    return _orDuplicate(saved);
  }

  static int _nextOrder(List<Category> categories) =>
      categories.fold(0, (max, c) => c.sortOrder > max ? c.sortOrder : max) + 1;
}

/// Cambia nombre o icono, u oculta/muestra una categoría. No se borran: sus
/// movimientos la necesitan.
final class UpdateCategory {
  const new(this._categories);

  final CategoryRepository _categories;

  Future<Result<Category>> call(
    Category category, {
    String? name,
    String? iconKey,
    bool? isArchived,
  }) async {
    final cleanName = name == null ? category.name : cleanText(name);
    if (cleanName == null) return await invalid(ValidationCodes.nameRequired);
    final saved = await guardUseCase<Category?>(() async {
      final updated = category.copyWith(
        name: cleanName,
        iconKey: iconKey,
        isArchived: isArchived,
      );
      if (!updated.isArchived) {
        final active = await _categories.getAll();
        final clash = active.any(
          (c) =>
              c.id != category.id &&
              c.kind == category.kind &&
              _sameName(c.name, cleanName),
        );
        if (clash) return null;
      }
      await _categories.save(updated);
      return updated;
    });
    return _orDuplicate(saved);
  }
}

bool _sameName(String a, String b) => a.toLowerCase() == b.toLowerCase();

/// `Ok(null)` = el nombre ya existe.
Result<Category> _orDuplicate(Result<Category?> result) => switch (result) {
  Ok(value: final category?) => Ok(category),
  Ok() => const Err(ValidationFailure(ValidationCodes.categoryExists)),
  Err(:final failure) => Err(failure),
};
