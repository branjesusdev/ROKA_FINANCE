import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// El ciclo lo marca el sueldo real, no solo el calendario.
///
/// Cada sueldo registrado se asocia al día de pago más cercano: si pagan el
/// 15 en lugar del 20, ese ciclo arranca el 15 y el anterior se cierra el
/// 14 (lo que sobró pasa a ser ahorro). Si el sueldo llega tarde, el ciclo
/// anterior se alarga hasta ese día. Sin sueldo registrado se usa el día
/// de pago configurado.
final class PayCycleResolver {
  new({required this.payday, required Iterable<DateTime> salaryDates})
    : _starts = _earliestByAnchor(payday, salaryDates);

  /// Toma como sueldo los ingresos en la categoría Salario.
  factory fromTransactions({
    required int payday,
    required Iterable<Transaction> transactions,
  }) => PayCycleResolver(
    payday: payday,
    salaryDates: [
      for (final t in transactions)
        if (t.isIncome && t.categoryId == DefaultCategories.salaryId) t.date,
    ],
  );

  /// Días hacia atrás que hay que mirar para resolver el ciclo actual y el
  /// anterior (dos meses largos + medio mes de margen).
  static const lookbackDays = 140;

  /// Días hacia adelante (sueldos registrados con fecha futura).
  static const lookaheadDays = 45;

  final int payday;

  /// Día de pago nominal → primer sueldo asociado a él.
  final Map<DateTime, DateTime> _starts;

  /// Ciclo real que contiene [date].
  PayCycle containing(DateTime date) {
    final day = _dayOf(date);
    final current = PayCycle.containing(day, payday: payday).start;
    final anchors = [_shift(current, -1), current, _shift(current, 1)];
    // El ancla anterior siempre empieza antes de [day]: el sueldo se asocia
    // al día de pago más cercano, así que nunca pasa del punto medio.
    var anchor = anchors.first;
    for (final candidate in anchors) {
      if (!_startFor(candidate).isAfter(day)) anchor = candidate;
    }
    return PayCycle.between(
      start: _startFor(anchor),
      endExclusive: _startFor(_shift(anchor, 1)),
      payday: payday,
    );
  }

  PayCycle previousOf(PayCycle cycle) => containing(
    DateTime(cycle.start.year, cycle.start.month, cycle.start.day - 1),
  );

  DateTime _startFor(DateTime anchor) => _starts[anchor] ?? anchor;

  DateTime _shift(DateTime anchor, int months) =>
      PayCycle.paydayIn(anchor.year, anchor.month + months, payday);

  static Map<DateTime, DateTime> _earliestByAnchor(
    int payday,
    Iterable<DateTime> salaryDates,
  ) {
    final starts = <DateTime, DateTime>{};
    for (final date in salaryDates) {
      final day = _dayOf(date);
      final anchor = _nearestPayday(day, payday);
      final known = starts[anchor];
      if (known == null || day.isBefore(known)) starts[anchor] = day;
    }
    return starts;
  }

  /// Día de pago nominal más cercano; en empate, el siguiente.
  static DateTime _nearestPayday(DateTime day, int payday) {
    final nominal = PayCycle.containing(day, payday: payday);
    final sinceStart = day.difference(nominal.start);
    final untilEnd = nominal.endExclusive.difference(day);
    return sinceStart < untilEnd ? nominal.start : nominal.endExclusive;
  }

  static DateTime _dayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
