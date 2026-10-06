import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayCycle con pago el 20', () {
    test('antes del 20 el ciclo empezó el 20 del mes anterior', () {
      final cycle = PayCycle.containing(DateTime(2026, 10, 3, 15), payday: 20);
      expect(cycle.start, DateTime(2026, 9, 20));
      expect(cycle.endExclusive, DateTime(2026, 10, 20));
      expect(cycle.lastDay, DateTime(2026, 10, 19));
    });

    test('el día de pago empieza un ciclo nuevo desde cero', () {
      final cycle = PayCycle.containing(DateTime(2026, 10, 20), payday: 20);
      expect(cycle.start, DateTime(2026, 10, 20));
      expect(cycle.endExclusive, DateTime(2026, 11, 20));
    });

    test('cruza el año', () {
      final cycle = PayCycle.containing(DateTime(2027, 1, 5), payday: 20);
      expect(cycle.start, DateTime(2026, 12, 20));
      expect(cycle.next.start, DateTime(2027, 1, 20));
      expect(cycle.previous.start, DateTime(2026, 11, 20));
    });

    test('cuenta los días que faltan incluyendo hoy', () {
      final cycle = PayCycle.containing(DateTime(2026, 10, 3), payday: 20);
      expect(cycle.daysLeft(DateTime(2026, 10, 3, 18)), 17);
      expect(cycle.daysLeft(DateTime(2026, 10, 19)), 1);
      expect(cycle.daysLeft(DateTime(2026, 10, 20)), 0);
      expect(cycle.totalDays, 30);
    });

    test('ubica un día del mes dentro del ciclo', () {
      final cycle = PayCycle.containing(DateTime(2026, 10, 3), payday: 20);
      expect(cycle.dateForDayOfMonth(25), DateTime(2026, 9, 25));
      expect(cycle.dateForDayOfMonth(5), DateTime(2026, 10, 5));
      expect(cycle.dateForDayOfMonth(20), DateTime(2026, 9, 20));
    });
  });

  test('un día de pago que no existe usa el último día del mes', () {
    final cycle = PayCycle.containing(DateTime(2027, 2, 28), payday: 31);
    expect(cycle.start, DateTime(2027, 2, 28));
    expect(cycle.endExclusive, DateTime(2027, 3, 31));

    final before = PayCycle.containing(DateTime(2027, 2, 27), payday: 31);
    expect(before.start, DateTime(2027, 1, 31));
    expect(before.endExclusive, DateTime(2027, 2, 28));
  });
}
