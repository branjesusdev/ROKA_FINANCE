import 'package:finance_app/application/categories/category_use_cases.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/infrastructure/repositories/drift_category_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_database.dart';

void main() {
  late DriftCategoryRepository repository;
  late CreateCategory create;
  late UpdateCategory update;

  setUp(() {
    repository = DriftCategoryRepository(createTestDatabase());
    create = CreateCategory(categories: repository, ids: SequentialIds());
    update = UpdateCategory(repository);
  });

  Category value(Result<Category> result) => (result as Ok<Category>).value;

  Matcher failsWith(String code) => isA<Err<Category>>().having(
    (r) => r.failure,
    'failure',
    isA<ValidationFailure>().having((f) => f.message, 'code', code),
  );

  test('crea una categoría al final de su lista', () async {
    final before = await repository.getAll();
    final pets = value(
      await create(
        name: ' Mascotas ',
        kind: CategoryKind.expense,
        iconKey: 'pets',
      ),
    );

    expect(pets.name, 'Mascotas');
    final expenses = before.where((c) => c.kind == CategoryKind.expense);
    expect(
      pets.sortOrder,
      greaterThan(
        expenses.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b),
      ),
    );
    expect(await repository.getById(pets.id), pets);
  });

  test('no permite nombre vacío ni repetido', () async {
    await create(name: 'Mascotas', kind: CategoryKind.expense, iconKey: 'pets');

    expect(
      await create(name: '  ', kind: CategoryKind.expense, iconKey: 'pets'),
      failsWith(ValidationCodes.nameRequired),
    );
    expect(
      await create(
        name: 'mascotas',
        kind: CategoryKind.expense,
        iconKey: 'pets',
      ),
      failsWith(ValidationCodes.categoryExists),
    );
    // En otro tipo sí se puede.
    expect(
      await create(
        name: 'Mascotas',
        kind: CategoryKind.income,
        iconKey: 'pets',
      ),
      isA<Ok<Category>>(),
    );
  });

  test('crear una que estaba oculta la vuelve a mostrar', () async {
    final pets = value(
      await create(
        name: 'Mascotas',
        kind: CategoryKind.expense,
        iconKey: 'pets',
      ),
    );
    await update(pets, isArchived: true);

    final again = value(
      await create(
        name: 'Mascotas',
        kind: CategoryKind.expense,
        iconKey: 'coffee',
      ),
    );

    expect(again.id, pets.id);
    expect(again.isArchived, isFalse);
    expect(again.iconKey, 'coffee');
  });

  test('renombrar no puede chocar con otra activa', () async {
    final pets = value(
      await create(
        name: 'Mascotas',
        kind: CategoryKind.expense,
        iconKey: 'pets',
      ),
    );
    await create(name: 'Café', kind: CategoryKind.expense, iconKey: 'coffee');

    expect(
      await update(pets, name: 'café'),
      failsWith(ValidationCodes.categoryExists),
    );
    expect(value(await update(pets, name: 'Perros')).name, 'Perros');
  });
}
