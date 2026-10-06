import 'package:meta/meta.dart';

/// Intervalo de fechas `[start, endExclusive)`.
@immutable
final class DateRange {
  new(this.start, this.endExclusive)
    : assert(!endExclusive.isBefore(start), 'endExclusive antes de start');

  final DateTime start;
  final DateTime endExclusive;

  bool contains(DateTime date) =>
      !date.isBefore(start) && date.isBefore(endExclusive);

  @override
  bool operator ==(Object other) =>
      other is DateRange &&
      other.start == start &&
      other.endExclusive == endExclusive;

  @override
  int get hashCode => Object.hash(start, endExclusive);

  @override
  String toString() => 'DateRange($start, $endExclusive)';
}
