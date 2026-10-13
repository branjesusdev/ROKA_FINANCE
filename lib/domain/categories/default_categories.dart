import 'package:finance_app/domain/categories/category.dart';

/// Categorías iniciales. IDs fijos para que sean estables entre
/// instalaciones (útil para una futura sincronización).
abstract final class DefaultCategories {
  static const debtsId = 'seed-expense-debts';

  /// Ahorro e inversión: cuenta como ahorro, no como gasto.
  static const investmentsId = 'seed-expense-investments';

  /// El ingreso en esta categoría marca el inicio de un ciclo.
  static const salaryId = 'seed-income-salary';

  /// Añadida en el esquema v3 (también se inserta al migrar).
  static const groceries = Category(
    id: 'seed-expense-groceries',
    name: 'Mercado',
    kind: CategoryKind.expense,
    iconKey: 'groceries',
    sortOrder: 13,
  );

  /// Cuadre de saldo: lo que falta frente al dinero real (gastos que no se
  /// anotaron). Archivada: no aparece al registrar, solo la usa el cuadre.
  /// Añadida en el esquema v4.
  static const untracked = Category(
    id: 'seed-expense-untracked',
    name: 'Gastos sin registrar',
    kind: CategoryKind.expense,
    iconKey: 'untracked',
    sortOrder: 14,
    isArchived: true,
  );

  /// Cuadre de saldo: dinero real que no estaba registrado (p. ej. lo que
  /// tenías al empezar). No cuenta como ingreso. Añadida en el esquema v4.
  static const balanceAdjustment = Category(
    id: 'seed-income-balance',
    name: 'Saldo inicial / ajuste',
    kind: CategoryKind.income,
    iconKey: 'balance',
    sortOrder: 4,
    isArchived: true,
  );

  /// Gastos que no son del día a día: se planean por mes (mercado,
  /// arriendo, servicios…) o son un cuadre. No cuentan para el tope diario.
  static const monthlyPlannedIds = {
    'seed-expense-housing',
    'seed-expense-education',
    'seed-expense-health',
    debtsId,
    'seed-expense-services',
    'seed-expense-family',
    'seed-expense-groceries',
    'seed-expense-untracked',
  };

  /// Plata apartada para pagos que no son mensuales (SOAT, matrícula…).
  /// Cuenta como ahorro, no como gasto. Archivada: solo la usan los
  /// apartados. Añadida en el esquema v5.
  static const provisions = Category(
    id: 'seed-expense-provisions',
    name: 'Apartados',
    kind: CategoryKind.expense,
    iconKey: 'provisions',
    sortOrder: 15,
    isArchived: true,
    countsAsSaving: true,
  );

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
      id: investmentsId,
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
    groceries,
    untracked,
    provisions,
  ];

  /// Ingreso extraordinario genérico (ya existía; desde v9 se marca como
  /// extraordinario).
  static const extraordinaryId = 'seed-income-extraordinary';

  /// Ingresos que no llegan cada mes. Añadidos en el esquema v9 (también se
  /// insertan al migrar). La IA y el tope diario no los cuentan como dinero
  /// mensual permanente.
  static const extraordinaryIncomes = <Category>[
    Category(
      id: 'seed-income-prima',
      name: 'Prima de servicios',
      kind: CategoryKind.income,
      iconKey: 'bonus',
      sortOrder: 5,
      isExtraordinary: true,
    ),
    Category(
      id: 'seed-income-severance',
      name: 'Cesantías',
      kind: CategoryKind.income,
      iconKey: 'severance',
      sortOrder: 6,
      isExtraordinary: true,
    ),
    Category(
      id: 'seed-income-severance-interest',
      name: 'Intereses de cesantías',
      kind: CategoryKind.income,
      iconKey: 'interest',
      sortOrder: 7,
      isExtraordinary: true,
    ),
    Category(
      id: 'seed-income-bonus',
      name: 'Bonificaciones',
      kind: CategoryKind.income,
      iconKey: 'bonus',
      sortOrder: 8,
      isExtraordinary: true,
    ),
    Category(
      id: 'seed-income-commissions',
      name: 'Comisiones',
      kind: CategoryKind.income,
      iconKey: 'commission',
      sortOrder: 9,
      isExtraordinary: true,
    ),
    Category(
      id: 'seed-income-refunds',
      name: 'Devoluciones',
      kind: CategoryKind.income,
      iconKey: 'refund',
      sortOrder: 10,
      isExtraordinary: true,
    ),
    Category(
      id: 'seed-income-asset-sale',
      name: 'Venta de activos',
      kind: CategoryKind.income,
      iconKey: 'asset_sale',
      sortOrder: 11,
      isExtraordinary: true,
    ),
    Category(
      id: 'seed-income-business',
      name: 'Utilidades de negocio',
      kind: CategoryKind.income,
      iconKey: 'business',
      sortOrder: 12,
      isExtraordinary: true,
    ),
  ];

  static const incomes = <Category>[
    Category(
      id: salaryId,
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
      id: extraordinaryId,
      name: 'Ingresos extraordinarios',
      kind: CategoryKind.income,
      iconKey: 'extraordinary_income',
      sortOrder: 2,
      isExtraordinary: true,
    ),
    Category(
      id: 'seed-income-other',
      name: 'Otros',
      kind: CategoryKind.income,
      iconKey: 'other',
      sortOrder: 3,
    ),
    balanceAdjustment,
    ...extraordinaryIncomes,
  ];

  static const List<Category> all = [...expenses, ...incomes];
}
