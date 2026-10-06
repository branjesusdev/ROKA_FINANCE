import 'package:finance_app/domain/shared/date_range.dart';
import 'package:meta/meta.dart';

/// Mes calendario (período de presupuestos y reportes).
@immutable
final class YearMonth implements Comparable<YearMonth> {
  const new(this.year, this.month)
    : assert(month >= 1 && month <= monthsPerYear, 'mes inválido');

  factory fromDate(DateTime date) => YearMonth(date.year, date.month);

  static const monthsPerYear = 12;

  final int year;
  final int month;

  int get _index => year * monthsPerYear + (month - 1);

  YearMonth addMonths(int months) {
    final index = _index + months;
    return YearMonth(index ~/ monthsPerYear, index % monthsPerYear + 1);
  }

  YearMonth get next => addMonths(1);
  YearMonth get previous => addMonths(-1);

  /// Meses desde este mes hasta [other] (negativo si [other] es anterior).
  int monthsUntil(YearMonth other) => other._index - _index;

  DateRange get range =>
      DateRange(DateTime(year, month), DateTime(year, month + 1));

  bool contains(DateTime date) => date.year == year && date.month == month;

  bool isBefore(YearMonth other) => _index < other._index;

  @override
  int compareTo(YearMonth other) => _index.compareTo(other._index);

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'YearMonth($year-$month)';
}
