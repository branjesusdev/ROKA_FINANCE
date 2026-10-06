import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';

final class SavingsStatus {
  const new({
    required this.targetRate,
    required this.target,
    required this.actual,
    required this.light,
  });

  final Percentage targetRate;
  final Money target;
  final Money actual;
  final TrafficLight light;

  /// Porcentaje de la meta alcanzado. `null` si la meta es cero.
  Percentage? get achieved => Percentage.ratio(actual, target);

  Money get remaining => (target - actual).max(Money.zero);
}

/// Regla de ahorro: meta = ingreso × porcentaje configurado.
final class SavingsTargetEvaluator {
  const new();

  SavingsStatus evaluate({
    required Money income,
    required Money actualSavings,
    required Percentage targetRate,
  }) {
    final target = income.applyPercentage(targetRate);
    final TrafficLight light;
    if (actualSavings >= target && !actualSavings.isNegative) {
      light = TrafficLight.ok;
    } else if (actualSavings.isPositive) {
      light = TrafficLight.warning;
    } else {
      light = TrafficLight.critical;
    }
    return SavingsStatus(
      targetRate: targetRate,
      target: target,
      actual: actualSavings,
      light: light,
    );
  }
}
