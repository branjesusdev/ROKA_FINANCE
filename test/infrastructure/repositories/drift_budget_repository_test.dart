import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/infrastructure/repositories/drift_budget_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late DriftBudgetRepository repository;

  const food = 'seed-expense-food';
  const october = YearMonth(2026, 10);

  BudgetLine line(String id, YearMonth period, int pesos) => BudgetLine(
    id: id,
    period: period,
    categoryId: food,
    limit: Money.pesos(pesos),
  );

  setUp(() => repository = DriftBudgetRepository(createTestDatabase()));

  test('una línea por categoría y mes: reemplaza el límite', () async {
    await repository.save(line('b1', october, 500000));
    await repository.save(line('b2', october, 600000));

    expect(await repository.getByMonth(october), [line('b1', october, 600000)]);
  });

  test('meses distintos son independientes', () async {
    await repository.save(line('b1', october, 500000));
    await repository.save(line('b2', october.next, 450000));

    expect(await repository.getByMonth(october), hasLength(1));
    expect(await repository.getByMonth(october.next), [
      line('b2', october.next, 450000),
    ]);
  });

  test('delete elimina la línea', () async {
    await repository.save(line('b1', october, 500000));
    await repository.delete('b1');

    expect(await repository.getByMonth(october), isEmpty);
  });
}
