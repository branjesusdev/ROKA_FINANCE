import 'package:finance_app/application/transactions/frequent_categories.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  const selector = FrequentCategories();

  test('sin historial respeta el orden por defecto', () {
    final result = selector.select(
      categories: DefaultCategories.all,
      recent: const [],
      kind: CategoryKind.expense,
      limit: 3,
    );

    expect(result.map((c) => c.name), [
      'Alimentación',
      'Vivienda',
      'Transporte',
    ]);
  });

  test('las más usadas primero, excluyendo archivadas y otro tipo', () {
    final categories = [
      ...DefaultCategories.all.where((c) => c.id != 'seed-expense-health'),
      DefaultCategories.expenses
          .firstWhere((c) => c.id == 'seed-expense-health')
          .copyWith(isArchived: true),
    ];
    final result = selector.select(
      categories: categories,
      recent: [
        expense(1, category: 'seed-expense-transport'),
        expense(1, category: 'seed-expense-transport'),
        expense(1, category: 'seed-expense-entertainment'),
        expense(1, category: 'seed-expense-health'),
        income(1, category: 'seed-income-salary'),
      ],
      kind: CategoryKind.expense,
      limit: 3,
    );

    expect(result.map((c) => c.id), [
      'seed-expense-transport',
      'seed-expense-entertainment',
      'seed-expense-food',
    ]);
  });
}
