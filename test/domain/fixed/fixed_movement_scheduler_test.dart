import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  final today = DateTime(2026, 10, 3, 18);
  final cycle = PayCycle.containing(today, payday: 20);

  FixedMovement fixed(
    String name,
    int day, {
    TransactionKind kind = TransactionKind.expense,
    bool isActive = true,
    bool isVariable = false,
    DateTime? lastPostedOn,
  }) => FixedMovement(
    id: name,
    name: name,
    kind: kind,
    amount: const Money.pesos(100000),
    categoryId: 'cat',
    dayOfMonth: day,
    isActive: isActive,
    isVariable: isVariable,
    lastPostedOn: lastPostedOn,
  );

  FixedSchedule schedule(List<FixedMovement> movements) =>
      const FixedMovementScheduler().schedule(
        movements: movements,
        cycle: cycle,
        today: today,
      );

  test('separa los que ya llegaron de los que faltan, por fecha', () {
    final result = schedule([
      fixed('Colegio', 10),
      fixed('Arriendo', 1),
      fixed('Sueldo', 20, kind: TransactionKind.income),
      fixed('Hoy', 3),
    ]);

    expect(result.due.map((s) => s.movement.name), [
      'Sueldo',
      'Arriendo',
      'Hoy',
    ]);
    expect(result.due.first.date, DateTime(2026, 9, 20));
    expect(result.upcoming.map((s) => s.movement.name), ['Colegio']);
    expect(result.upcoming.single.date, DateTime(2026, 10, 10));
    expect(result.upcomingExpenses, const Money.pesos(100000));
    expect(result.upcomingIncome, Money.zero);
  });

  test('no repite lo ya registrado en este ciclo ni los pausados', () {
    final result = schedule([
      fixed('Arriendo', 1, lastPostedOn: DateTime(2026, 10)),
      fixed('Colegio', 10, lastPostedOn: DateTime(2026, 10, 10)),
      fixed('Entrenos', 2, isActive: false),
    ]);

    expect(result.due, isEmpty);
    expect(result.upcoming, isEmpty);
  });

  test('lo registrado el ciclo anterior vuelve a tocar en este', () {
    final result = schedule([
      fixed('Arriendo', 1, lastPostedOn: DateTime(2026, 9)),
    ]);

    expect(result.due.single.date, DateTime(2026, 10));
  });

  group('ciclo que arrancó con sueldo adelantado', () {
    // Sueldo el 6 oct con día de pago 20: ciclo 6 oct → 19 nov.
    final long = PayCycle.between(
      start: DateTime(2026, 10, 6),
      endExclusive: DateTime(2026, 11, 20),
      payday: 20,
    );

    test('un día del mes que cae dos veces en el ciclo se registra dos '
        'veces', () {
      final result = const FixedMovementScheduler().schedule(
        movements: [fixed('Colegio', 10)],
        cycle: long,
        today: DateTime(2026, 11, 12),
      );

      expect(result.due.map((s) => s.date), [
        DateTime(2026, 10, 10),
        DateTime(2026, 11, 10),
      ]);
    });

    test('el sueldo fijo no se duplica si ya se anotó a mano', () {
      final result = const FixedMovementScheduler().schedule(
        movements: [fixed('Sueldo', 20, kind: TransactionKind.income)],
        cycle: long,
        today: DateTime(2026, 10, 25),
        cycleTransactions: [
          income(4000000, category: 'cat', date: DateTime(2026, 10, 6)),
        ],
      );

      expect(result.due, isEmpty);
      expect(result.upcoming, isEmpty);
      expect(result.covered.single.date, DateTime(2026, 10, 20));
    });

    test('el sueldo fijo futuro tampoco suma como ingreso pendiente', () {
      final result = const FixedMovementScheduler().schedule(
        movements: [fixed('Sueldo', 20, kind: TransactionKind.income)],
        cycle: long,
        today: DateTime(2026, 10, 7),
        cycleTransactions: [
          income(4000000, category: 'cat', date: DateTime(2026, 10, 6)),
        ],
      );

      expect(result.upcomingIncome, Money.zero);
      expect(result.covered, isEmpty, reason: 'aún no llega su día');
    });
  });

  test('valor variable: su día no lo registra solo, espera la factura y '
      'su estimado sigue descontándose', () {
    final result = schedule([
      fixed('Luz', 1, isVariable: true),
      fixed('Internet', 10, isVariable: true),
      fixed('Arriendo', 1),
    ]);

    expect(result.due.map((s) => s.movement.name), ['Arriendo']);
    expect(result.awaitingAmount.map((s) => s.movement.name), ['Luz']);
    expect(result.upcoming.map((s) => s.movement.name), ['Internet']);
    expect(result.upcomingExpenses, const Money.pesos(200000));
  });
}
