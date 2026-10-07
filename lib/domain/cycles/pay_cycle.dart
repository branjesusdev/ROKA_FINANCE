import 'package:finance_app/domain/shared/date_range.dart';
import 'package:meta/meta.dart';

/// Ciclo de sueldo: desde el día de pago hasta el día anterior al siguiente
/// pago (p. ej. 20 sep → 19 oct). Cada ciclo empieza "de cero".
///
/// [PayCycle.containing] da el ciclo "nominal" según el día configurado; el
/// ciclo real (que arranca cuando llega el sueldo) lo calcula
/// `PayCycleResolver`.
///
/// Si el día de pago no existe en un mes (31 en febrero) se usa el último
/// día de ese mes.
@immutable
final class PayCycle {
  const new _(this.payday, this.start, this.endExclusive);

  /// Ciclo que contiene [date] para el día de pago [payday] (1–31).
  factory containing(DateTime date, {required int payday}) {
    assert(payday >= minPayday && payday <= maxPayday, 'día de pago inválido');
    final day = DateTime(date.year, date.month, date.day);
    var start = paydayIn(day.year, day.month, payday);
    if (day.isBefore(start)) start = paydayIn(day.year, day.month - 1, payday);
    return PayCycle._(
      payday,
      start,
      paydayIn(start.year, start.month + 1, payday),
    );
  }

  /// Ciclo con fechas explícitas (p. ej. arrancó el día que llegó el
  /// sueldo).
  factory between({
    required DateTime start,
    required DateTime endExclusive,
    required int payday,
  }) {
    assert(endExclusive.isAfter(start), 'ciclo vacío');
    return PayCycle._(
      payday,
      DateTime(start.year, start.month, start.day),
      DateTime(endExclusive.year, endExclusive.month, endExclusive.day),
    );
  }

  static const minPayday = 1;
  static const maxPayday = 31;

  final int payday;

  /// Primer día del ciclo (día de pago), a medianoche.
  final DateTime start;

  /// Día de pago siguiente (excluido).
  final DateTime endExclusive;

  DateRange get range => DateRange(start, endExclusive);

  /// Último día incluido en el ciclo.
  DateTime get lastDay =>
      DateTime(endExclusive.year, endExclusive.month, endExclusive.day - 1);

  PayCycle get previous => PayCycle.containing(
    DateTime(start.year, start.month, start.day - 1),
    payday: payday,
  );

  PayCycle get next => PayCycle.containing(endExclusive, payday: payday);

  bool contains(DateTime date) => range.contains(date);

  /// Días que faltan incluyendo [today]; 0 si el ciclo ya terminó.
  int daysLeft(DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    if (!day.isBefore(endExclusive)) return 0;
    final from = day.isBefore(start) ? start : day;
    return _daysBetween(from, endExclusive);
  }

  int get totalDays => _daysBetween(start, endExclusive);

  /// Fecha del día [day] dentro del ciclo (p. ej. arriendo el 5). Si el día
  /// no existe en el mes se usa el último día del mes.
  DateTime dateForDayOfMonth(int day) {
    final inStartMonth = paydayIn(start.year, start.month, day);
    return inStartMonth.isBefore(start)
        ? paydayIn(start.year, start.month + 1, day)
        : inStartMonth;
  }

  /// Todas las fechas del día [day] dentro del ciclo. Un ciclo largo (sueldo
  /// adelantado) puede contener dos veces el mismo día del mes.
  List<DateTime> datesForDayOfMonth(int day) => [
    for (
      var month = DateTime(start.year, start.month);
      month.isBefore(endExclusive);
      month = DateTime(month.year, month.month + 1)
    )
      if (contains(paydayIn(month.year, month.month, day)))
        paydayIn(month.year, month.month, day),
  ];

  /// [day] del mes indicado, limitado al último día de ese mes. Acepta
  /// meses fuera de rango (13 = enero del año siguiente).
  static DateTime paydayIn(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }

  // Con horario de verano un día puede durar 23 o 25 horas: se redondea.
  static int _daysBetween(DateTime from, DateTime to) =>
      (to.difference(from).inHours / Duration.hoursPerDay).round();

  @override
  bool operator ==(Object other) =>
      other is PayCycle &&
      other.payday == payday &&
      other.start == start &&
      other.endExclusive == endExclusive;

  @override
  int get hashCode => Object.hash(payday, start, endExclusive);

  @override
  String toString() => 'PayCycle($start, $endExclusive)';
}
