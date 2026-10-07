import 'package:finance_app/domain/shared/percentage.dart';
import 'package:meta/meta.dart';

/// Monto en centavos de peso colombiano. Aritmética exacta con enteros.
@immutable
final class Money implements Comparable<Money> {
  const new(this.cents);

  const new pesos(int pesos) : cents = pesos * centsPerPeso;

  static const centsPerPeso = 100;
  static const zero = Money(0);

  final int cents;

  bool get isZero => cents == 0;
  bool get isPositive => cents > 0;
  bool get isNegative => cents < 0;

  Money get abs => Money(cents.abs());

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);
  Money operator -() => Money(-cents);
  bool operator <(Money other) => cents < other.cents;
  bool operator <=(Money other) => cents <= other.cents;
  bool operator >(Money other) => cents > other.cents;
  bool operator >=(Money other) => cents >= other.cents;

  /// Multiplica por [factor] redondeando al centavo más cercano.
  Money times(num factor) => Money((cents * factor).round());

  /// Divide en [parts] partes iguales redondeando al centavo.
  Money divide(int parts) => Money((cents / parts).round());

  /// Divide en [parts] partes redondeando hacia arriba al peso: al sumar
  /// las partes nunca falta.
  Money divideUp(int parts) {
    final perPart = (cents / parts).ceil();
    final remainder = perPart % centsPerPeso;
    return Money(remainder == 0 ? perPart : perPart + centsPerPeso - remainder);
  }

  Money applyPercentage(Percentage percentage) =>
      times(percentage.basisPoints / Percentage.basisPointsPerUnit);

  Money min(Money other) => this <= other ? this : other;
  Money max(Money other) => this >= other ? this : other;
  Money clamp(Money lower, Money upper) => max(lower).min(upper);

  static Money sum(Iterable<Money> values) =>
      values.fold(zero, (total, value) => total + value);

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => 'Money($cents)';
}
