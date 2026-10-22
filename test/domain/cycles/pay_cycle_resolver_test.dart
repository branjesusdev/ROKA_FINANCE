import 'package:finance_app/domain/cycles/pay_cycle_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PayCycleResolver resolver(List<DateTime> salaries) =>
      PayCycleResolver(payday: 20, salaryDates: salaries);

  test('sin sueldo registrado usa el día de pago configurado', () {
    final cycle = resolver([]).containing(DateTime(2026, 10, 6));

    expect(cycle.start, DateTime(2026, 9, 20));
    expect(cycle.endExclusive, DateTime(2026, 10, 20));
  });

  test('sueldo adelantado (15 en vez de 20): el ciclo arranca ese día y el '
      'anterior se cierra la víspera', () {
    final r = resolver([DateTime(2026, 9, 20), DateTime(2026, 10, 15, 9)]);

    final current = r.containing(DateTime(2026, 10, 16));
    expect(current.start, DateTime(2026, 10, 15));
    expect(current.endExclusive, DateTime(2026, 11, 20));

    final previous = r.previousOf(current);
    expect(previous.start, DateTime(2026, 9, 20));
    expect(previous.endExclusive, DateTime(2026, 10, 15));
  });

  test('el día que llega el sueldo ya cuenta como ciclo nuevo', () {
    final r = resolver([DateTime(2026, 10, 15)]);

    expect(
      r.containing(DateTime(2026, 10, 15, 8)).start,
      DateTime(2026, 10, 15),
    );
    expect(
      r.containing(DateTime(2026, 10, 14, 23)).start,
      DateTime(2026, 9, 20),
    );
  });

  test('sueldo tardío: el ciclo anterior se alarga hasta que llega', () {
    final r = resolver([DateTime(2026, 9, 20), DateTime(2026, 10, 22)]);

    final waiting = r.containing(DateTime(2026, 10, 21));
    expect(waiting.start, DateTime(2026, 9, 20));
    expect(waiting.endExclusive, DateTime(2026, 10, 22));

    expect(r.containing(DateTime(2026, 10, 22)).start, DateTime(2026, 10, 22));
  });

  test('empezar desde hoy: registrar el sueldo hoy arranca el ciclo hoy', () {
    final cycle = resolver([DateTime(2026, 10, 6)])
        .containing(DateTime(2026, 10, 6, 12));

    expect(cycle.start, DateTime(2026, 10, 6));
    expect(cycle.endExclusive, DateTime(2026, 11, 20));
  });

  test('dos pagos de sueldo cerca del mismo día de pago son un solo ciclo', () {
    final r = resolver([DateTime(2026, 10, 15), DateTime(2026, 10, 30)]);

    final cycle = r.containing(DateTime(2026, 11));
    expect(cycle.start, DateTime(2026, 10, 15));
    expect(cycle.endExclusive, DateTime(2026, 11, 20));
  });

  group('sueldo que aún no se registra', () {
    PayCycleResolver withToday(List<DateTime> salaries, DateTime today) =>
        PayCycleResolver(payday: 20, salaryDates: salaries, today: today);

    test('pasado el día de pago, sigue el ciclo anterior hasta mañana', () {
      final today = DateTime(2026, 10, 20, 9);
      final r = withToday([DateTime(2026, 9, 20)], today);

      final cycle = r.containing(today);
      expect(r.salaryLate, isTrue);
      expect(cycle.start, DateTime(2026, 9, 20));
      expect(cycle.endExclusive, DateTime(2026, 10, 21));
    });

    test('al registrarlo arranca el ciclo nuevo', () {
      final today = DateTime(2026, 10, 22);
      final r = withToday([
        DateTime(2026, 9, 20),
        DateTime(2026, 10, 22),
      ], today);

      expect(r.salaryLate, isFalse);
      expect(r.containing(today).start, DateTime(2026, 10, 22));
    });

    test('sin sueldos registrados antes no se alarga', () {
      final today = DateTime(2026, 10, 21);
      final r = withToday([], today);

      expect(r.salaryLate, isFalse);
      expect(r.containing(today).start, DateTime(2026, 10, 20));
    });

    test('pasada la gracia el ciclo empieza sin el sueldo', () {
      final today = DateTime(2026, 11, 4);
      final r = withToday([DateTime(2026, 9, 20)], today);

      expect(r.salaryLate, isFalse);
      expect(r.containing(today).start, DateTime(2026, 10, 20));
    });
  });
}
