import 'package:finance_app/domain/categories/category.dart';

/// Categorías iniciales. IDs fijos para que sean estables entre
/// instalaciones (útil para una futura sincronización).
abstract final class DefaultCategories {
  static const debtsId = 'seed-expense-debts';

  /// Añadida en el esquema v2 (también se inserta al migrar).
  static const sports = Category(
    id: 'seed-expense-sports',
    name: 'Deporte',
    kind: CategoryKind.expense,
    iconKey: 'sports',
    sortOrder: 12,
  );

  static const expenses = <Category>[
    Category(
      id: 'seed-expense-food',
      name: 'Alimentación',
      kind: CategoryKind.expense,
      iconKey: 'food',
    ),
    Category(
      id: 'seed-expense-housing',
      name: 'Vivienda',
      kind: CategoryKind.expense,
      iconKey: 'housing',
      sortOrder: 1,
    ),
    Category(
      id: 'seed-expense-transport',
      name: 'Transporte',
      kind: CategoryKind.expense,
      iconKey: 'transport',
      sortOrder: 2,
    ),
    Category(
      id: 'seed-expense-education',
      name: 'Educación',
      kind: CategoryKind.expense,
      iconKey: 'education',
      sortOrder: 3,
    ),
    Category(
      id: 'seed-expense-health',
      name: 'Salud',
      kind: CategoryKind.expense,
      iconKey: 'health',
      sortOrder: 4,
    ),
    Category(
      id: 'seed-expense-entertainment',
      name: 'Entretenimiento',
      kind: CategoryKind.expense,
      iconKey: 'entertainment',
      sortOrder: 5,
    ),
    Category(
      id: debtsId,
      name: 'Deudas',
      kind: CategoryKind.expense,
      iconKey: 'debts',
      sortOrder: 6,
    ),
    Category(
      id: 'seed-expense-services',
      name: 'Servicios',
      kind: CategoryKind.expense,
      iconKey: 'services',
      sortOrder: 7,
    ),
    Category(
      id: 'seed-expense-shopping',
      name: 'Compras',
      kind: CategoryKind.expense,
      iconKey: 'shopping',
      sortOrder: 8,
    ),
    Category(
      id: 'seed-expense-family',
      name: 'Hijos/Familia',
      kind: CategoryKind.expense,
      iconKey: 'family',
      sortOrder: 9,
    ),
    Category(
      id: 'seed-expense-investments',
      name: 'Inversiones',
      kind: CategoryKind.expense,
      iconKey: 'investments',
      sortOrder: 10,
      countsAsSaving: true,
    ),
    Category(
      id: 'seed-expense-other',
      name: 'Otros',
      kind: CategoryKind.expense,
      iconKey: 'other',
      sortOrder: 11,
    ),
    sports,
  ];

  static const incomes = <Category>[
    Category(
      id: 'seed-income-salary',
      name: 'Salario',
      kind: CategoryKind.income,
      iconKey: 'salary',
    ),
    Category(
      id: 'seed-income-additional',
      name: 'Ingresos adicionales',
      kind: CategoryKind.income,
      iconKey: 'additional_income',
      sortOrder: 1,
    ),
    Category(
      id: 'seed-income-extraordinary',
      name: 'Ingresos extraordinarios',
      kind: CategoryKind.income,
      iconKey: 'extraordinary_income',
      sortOrder: 2,
    ),
    Category(
      id: 'seed-income-other',
      name: 'Otros',
      kind: CategoryKind.income,
      iconKey: 'other',
      sortOrder: 3,
    ),
  ];

  static const List<Category> all = [...expenses, ...incomes];
}
