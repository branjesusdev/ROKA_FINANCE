import 'dart:math' as math;

import 'package:finance_app/domain/shared/percentage.dart';
import 'package:meta/meta.dart';

/// EA = efectiva anual, NMV = nominal anual mes vencido, EM = efectiva
/// mensual.
enum InterestRateType {
  effectiveAnnual,
  nominalAnnualMonthly,
  effectiveMonthly,
}

@immutable
final class InterestRate {
  const new({required this.rate, required this.type});

  static const _monthsPerYear = 12;

  final Percentage rate;
  final InterestRateType type;

  /// Tasa efectiva mensual como fracción (0.0139 = 1.39%).
  double get monthlyEffective => switch (type) {
    InterestRateType.effectiveAnnual =>
      math.pow(1 + rate.fraction, 1 / _monthsPerYear) - 1,
    InterestRateType.nominalAnnualMonthly => rate.fraction / _monthsPerYear,
    InterestRateType.effectiveMonthly => rate.fraction,
  }.toDouble();

  /// Tasa efectiva anual equivalente como fracción.
  double get annualEffective =>
      math.pow(1 + monthlyEffective, _monthsPerYear).toDouble() - 1;

  @override
  bool operator ==(Object other) =>
      other is InterestRate && other.rate == rate && other.type == type;

  @override
  int get hashCode => Object.hash(rate, type);
}
