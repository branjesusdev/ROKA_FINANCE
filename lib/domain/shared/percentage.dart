import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

/// Porcentaje con precisión de puntos básicos (1% = 100 bp). Puede ser
/// negativo (p. ej. variaciones).
@immutable
final class Percentage implements Comparable<Percentage> {
  const new basisPoints(this.basisPoints);

  const new whole(int percent) : basisPoints = percent * 100;

  factory fromFraction(double fraction) =>
      Percentage.basisPoints((fraction * basisPointsPerUnit).round());

  static const basisPointsPerUnit = 10000;
  static const zero = Percentage.basisPoints(0);
  static const hundred = Percentage.whole(100);

  final int basisPoints;

  /// `part / total`, o `null` si `total` es cero.
  static Percentage? ratio(Money part, Money total) =>
      total.isZero ? null : Percentage.fromFraction(part.cents / total.cents);

  /// Fracción decimal: 10% → 0.10.
  double get fraction => basisPoints / basisPointsPerUnit;

  /// Valor en porcentaje: 10% → 10.0.
  double get value => basisPoints / 100;

  bool get isNegative => basisPoints < 0;

  Percentage get abs => Percentage.basisPoints(basisPoints.abs());

  bool operator <(Percentage other) => basisPoints < other.basisPoints;
  bool operator <=(Percentage other) => basisPoints <= other.basisPoints;
  bool operator >(Percentage other) => basisPoints > other.basisPoints;
  bool operator >=(Percentage other) => basisPoints >= other.basisPoints;

  @override
  int compareTo(Percentage other) => basisPoints.compareTo(other.basisPoints);

  @override
  bool operator ==(Object other) =>
      other is Percentage && other.basisPoints == basisPoints;

  @override
  int get hashCode => basisPoints.hashCode;

  @override
  String toString() => 'Percentage(${value.toStringAsFixed(2)}%)';
}
