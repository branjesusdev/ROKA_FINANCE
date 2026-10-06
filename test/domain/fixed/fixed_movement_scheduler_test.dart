import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 3, 18);
  final cycle = PayCycle.containing(today, payday: 20);

  FixedMovement fixed(
    String name,
    int day, {
    TransactionKind kind = TransactionKind.expense,
    bool isActive = true,
    DateTime? lastPostedOn,
  }) => FixedMovement(
    id: name,
    name: name,
    kind: kind,
    amount: const Money.pesos(100000),
    categoryId: 'cat',
    dayOfMonth: day,
    isActive: isActive,
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
}
