import 'package:finance_app/application/dashboard/cycle_pulse.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  final cycle = PayCycle.containing(DateTime(2026, 10, 5), payday: 1);
  final previous = cycle.previous;
  final today = DateTime(2026, 10, 4, 20);

  CyclePulse build(
    List<Transaction> current, {
    List<Transaction> before = const [],
    DateTime? on,
  }) => const CyclePulseBuilder().build(
    cycle: cycle,
    today: on ?? today,
    cycleTransactions: current,
    previousCycle: previous,
    previousCycleTransactions: before,
    savingCategoryIds: const {'savings'},
  );

  test('sin registros: vacío', () {
    expect(build(const []).isEmpty, isTrue);
  });

  test('día a día, promedio, días sin gastos y constancia', () {
    final pulse = build([
      expense(20000, date: DateTime(2026, 10)),
      expense(10000, date: DateTime(2026, 10, 3)),
      expense(500000, category: 'savings', date: DateTime(2026, 10, 3)),
    ]);

    expect(pulse.daysElapsed, 4);
    expect(pulse.dayToDaySpent, const Money.pesos(30000));
    expect(pulse.averagePerDay, const Money.pesos(7500));
    expect(pulse.daysWithoutSpending, 2);
    expect(pulse.daysRegistered, 2);
    expect(pulse.previousAtSamePoint, isNull, reason: 'sin ciclo anterior');
    expect(pulse.busiestWeekday, isNull, reason: 'menos de dos semanas');
  });

  test('compara con el ciclo pasado en los mismos días', () {
    final pulse = build(
      [expense(30000, date: DateTime(2026, 10, 2))],
      before: [
        expense(20000, date: DateTime(2026, 9, 2)),
        // Fuera de los primeros 4 días del ciclo pasado: no cuenta.
        expense(90000, date: DateTime(2026, 9, 20)),
      ],
    );

    expect(pulse.previousAtSamePoint, const Money.pesos(20000));
    expect(pulse.changeVsPrevious, const Money.pesos(10000));
    expect(pulse.changeShare, const Percentage.whole(50));
  });

  test('categoría principal y gasto más grande sin contar fijos', () {
    final rent = Transaction(
      id: 'rent',
      kind: TransactionKind.expense,
      amount: const Money.pesos(1000000),
      categoryId: 'housing',
      date: DateTime(2026, 10),
      createdAt: DateTime(2026, 10),
      fixedMovementId: 'fixed-rent',
    );
    final shoes = expense(
      150000,
      category: 'shopping',
      date: DateTime(2026, 10, 2),
    );
    final pulse = build([rent, shoes, expense(50000)]);

    expect(pulse.topCategory?.categoryId, 'housing');
    expect(pulse.biggestExpense, shoes);
  });

  test('día de la semana con más gasto tras dos semanas', () {
    final pulse = build([
      // 3 y 10 oct 2026 son sábado.
      expense(40000, date: DateTime(2026, 10, 3)),
      expense(40000, date: DateTime(2026, 10, 10)),
      expense(30000, date: DateTime(2026, 10, 6)),
    ], on: DateTime(2026, 10, 15));

    expect(pulse.busiestWeekday, DateTime.saturday);
  });
}
