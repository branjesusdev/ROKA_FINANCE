import 'package:finance_app/application/dashboard/cycle_ledger.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle_resolver.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  test('acumula lo que sobró de cada ciclo hasta el dinero total de hoy', () {
    final today = DateTime(2026, 10, 25);
    const salary = DefaultCategories.salaryId;
    final transactions = [
      income(3000000, category: salary, date: DateTime(2026, 8, 20)),
      expense(2500000, date: DateTime(2026, 9)),
      income(3000000, category: salary, date: DateTime(2026, 9, 20)),
      expense(3200000, date: DateTime(2026, 10)),
      income(3000000, category: salary, date: DateTime(2026, 10, 20)),
      expense(1000000, date: DateTime(2026, 10, 22)),
    ];

    final ledger = const CycleLedgerBuilder().build(
      resolver: PayCycleResolver.fromTransactions(
        payday: 20,
        transactions: transactions,
        today: today,
      ),
      today: today,
      transactions: transactions,
      savingCategoryIds: const {},
    );

    expect(ledger.entries.map((e) => e.result), [
      const Money.pesos(500000),
      const Money.pesos(-200000),
      const Money.pesos(2000000),
    ]);
    expect(ledger.entries.map((e) => e.accumulated), [
      const Money.pesos(500000),
      const Money.pesos(300000),
      const Money.pesos(2300000),
    ]);
    expect(ledger.entries.last.isCurrent, isTrue);
    expect(ledger.current, const Money.pesos(2000000));
    expect(ledger.carried, const Money.pesos(300000));
    expect(ledger.total, const Money.pesos(2300000));
  });
}
