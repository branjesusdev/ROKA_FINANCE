import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:meta/meta.dart';

/// Tope para el gasto del día a día (almuerzos, transporte, antojos…).
@immutable
final class DailySpendingCap {
  const new({
    required this.cap,
    required this.spentToday,
    required this.reserved,
    required this.light,
  });

  /// Lo máximo para gastar hoy sin comprometer el resto del ciclo.
  final Money cap;

  /// Gasto del día a día registrado hoy.
  final Money spentToday;

  /// Apartado del dinero disponible: gastos del mes aún por hacer (mercado,
  /// servicios…) y ahorro del ciclo pendiente.
  final Money reserved;

  final TrafficLight light;

  Money get remainingToday => cap - spentToday;

  bool get exceeded => spentToday > cap;

  /// % del tope usado hoy (`null` si el tope es cero).
  Percentage? get usage => Percentage.ratio(spentToday, cap);
}

/// Reparte lo que queda del ciclo entre los días que faltan, después de
/// apartar fijos, gastos del mes y el ahorro.
final class DailySpendingCapCalculator {
  const new();

  /// [available]: lo que queda del ciclo después de fijos pendientes.
  /// [spentToday]: gasto del día a día de hoy (ya descontado de
  /// [available]); se suma de vuelta para que el tope no baje mientras
  /// gastas.
  DailySpendingCap? calculate({
    required Money available,
    required int daysLeft,
    required Money spentToday,
    required Money monthlyReserve,
    required Money savingsReserve,
    required TrafficLightThresholds thresholds,
  }) {
    if (daysLeft <= 0) return null;
    final reserved = monthlyReserve + savingsReserve;
    final free = (available + spentToday - reserved).max(Money.zero);
    final cap = free.divide(daysLeft);
    final usage = Percentage.ratio(spentToday, cap);
    return DailySpendingCap(
      cap: cap,
      spentToday: spentToday,
      reserved: reserved,
      light: usage == null
          ? (spentToday.isPositive ? TrafficLight.critical : TrafficLight.ok)
          : thresholds.classifyUsage(usage),
    );
  }
}
