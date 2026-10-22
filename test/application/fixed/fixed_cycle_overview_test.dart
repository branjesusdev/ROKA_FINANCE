import 'package:finance_app/application/fixed/fixed_cycle_status.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const housing = 'seed-expense-housing';
  final groceries = DefaultCategories.groceries.id;
  var seq = 0;

  FixedCycleStatus status(
    int pesos,
    String category,
    FixedCycleState state, {
    TransactionKind kind = TransactionKind.expense,
  }) => FixedCycleStatus(
    movement: FixedMovement(
      id: 'f${seq++}',
      name: 'Fijo $seq',
      kind: kind,
      amount: Money.pesos(pesos),
      categoryId: category,
      dayOfMonth: 5,
    ),
    state: state,
  );

  final overview = const FixedCycleOverviewBuilder().build(
    statuses: [
      status(1200000, housing, FixedCycleState.paid),
      status(300000, groceries, FixedCycleState.upcoming),
      status(100000, groceries, FixedCycleState.overdue),
      status(80000, housing, FixedCycleState.paused),
      status(50000, housing, FixedCycleState.notThisCycle),
      status(
        4000000,
        'seed-income-salary',
        FixedCycleState.received,
        kind: TransactionKind.income,
      ),
    ],
    categories: {for (final c in DefaultCategories.all) c.id: c},
  );

  test('cuenta solo lo que toca este ciclo: pagado, por pagar y vencido', () {
    expect(overview.expenseTotal, const Money.pesos(1600000));
    expect(overview.paid, const Money.pesos(1200000));
    expect(overview.pending, const Money.pesos(400000));
    expect(overview.overdue, const Money.pesos(100000));
    expect(overview.expenseCount, 3);
    expect(overview.overdueCount, 1);
    expect(overview.pausedCount, 1);
    expect(overview.paidShare, const Percentage.whole(75));
    expect(overview.net, const Money.pesos(2400000));
  });

  test('por categoría de mayor a menor, sumando el total', () {
    expect(overview.byCategory.map((c) => c.categoryId), [housing, groceries]);
    expect(overview.byCategory.last.count, 2);
    expect(
      Money.sum(overview.byCategory.map((c) => c.amount)),
      overview.expenseTotal,
    );
  });
}
