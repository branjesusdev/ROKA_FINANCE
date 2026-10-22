import 'package:finance_app/application/transactions/cycle_movements.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var seq = 0;
  Transaction tx(
    int pesos,
    DateTime date,
    String category, {
    TransactionKind kind = TransactionKind.expense,
  }) => Transaction(
    id: 't${seq++}',
    kind: kind,
    amount: Money.pesos(pesos),
    categoryId: category,
    date: date,
    createdAt: date,
  );

  final cycle = PayCycle.containing(DateTime(2026, 10, 3), payday: 20);
  final food = DefaultCategories.all.firstWhere((c) => c.iconKey == 'food').id;
  final groceries = DefaultCategories.groceries.id;

  final movements = const CycleMovementsBuilder().build(
    cycle: cycle,
    categories: DefaultCategories.all,
    transactions: [
      tx(
        3000000,
        DateTime(2026, 9, 20),
        DefaultCategories.salaryId,
        kind: TransactionKind.income,
      ),
      tx(20000, DateTime(2026, 9, 21), food),
      tx(30000, DateTime(2026, 10, 2), food),
      tx(250000, DateTime(2026, 10), groceries),
      // Fuera del ciclo.
      tx(99000, DateTime(2026, 9, 19), food),
    ],
  );

  test('solo el ciclo, del más reciente al más antiguo', () {
    expect(movements.transactions, hasLength(4));
    expect(movements.transactions.first.date, DateTime(2026, 10, 2));
  });

  test('la dona y la lista filtrada suman lo mismo', () {
    final foodTotal = movements.expenseTotals.firstWhere(
      (t) => t.categoryId == food,
    );
    final foodList = movements.filtered(
      TransactionKind.expense,
      categoryId: food,
    );

    expect(foodTotal.amount, const Money.pesos(50000));
    expect(Money.sum(foodList.map((t) => t.amount)), foodTotal.amount);
    expect(
      movements.totalOf(TransactionKind.expense),
      const Money.pesos(300000),
    );
    expect(
      movements.totalOf(TransactionKind.income),
      const Money.pesos(3000000),
    );
    expect(movements.expenseTotals.first.categoryId, groceries);
  });
}
