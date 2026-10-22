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
    this.surplus = Money.zero,
  });

  /// Lo máximo para gastar hoy sin comprometer el resto del ciclo.
  final Money cap;

  /// Gasto del día a día registrado hoy.
  final Money spentToday;

  /// Apartado del dinero disponible: gastos del mes aún por hacer (mercado,
  /// servicios…) y ahorro del ciclo pendiente.
  final Money reserved;

  final TrafficLight light;

  /// Lo que sobra del día a día al repartir parejo todo el ciclo: no se
  /// gasta, se aparta para pagos del año o metas.
  final Money surplus;

  Money get remainingToday => cap - spentToday;

  bool get exceeded => spentToday > cap;

  /// % del tope usado hoy (`null` si el tope es cero).
  Percentage? get usage => Percentage.ratio(spentToday, cap);
}

/// Reparte lo que queda del ciclo entre los días que faltan, después de
/// apartar fijos, gastos del mes y el ahorro.
///
/// El tope nunca pasa del promedio del ciclo completo: si gastaste menos los
/// primeros días, lo que sobra no se vuelve "puedes gastarlo todo el último
/// día", queda como [DailySpendingCap.surplus] para apartar.
final class DailySpendingCapCalculator {
  const new();

  /// [available]: lo que queda del ciclo después de fijos pendientes.
  /// [spentToday]: gasto del día a día de hoy (ya descontado de
  /// [available]); se suma de vuelta para que el tope no baje mientras
  /// gastas.
  /// [trackedDays]: días del ciclo con registro (desde que empezó o desde
  /// que empezaste a anotar) y [spentBeforeToday] el día a día gastado en
  /// ellos antes de hoy; sin ellos no se equilibra.
  DailySpendingCap? calculate({
    required Money available,
    required int daysLeft,
    required Money spentToday,
    required Money monthlyReserve,
    required Money savingsReserve,
    required TrafficLightThresholds thresholds,
    int? trackedDays,
    Money spentBeforeToday = Money.zero,
  }) {
    if (daysLeft <= 0) return null;
    final reserved = monthlyReserve + savingsReserve;
    final free = (available + spentToday - reserved).max(Money.zero);
    var cap = free.divide(daysLeft);
    var surplus = Money.zero;
    if (trackedDays != null && trackedDays > daysLeft) {
      final balanced = (free + spentBeforeToday).divide(trackedDays);
      if (balanced < cap) {
        cap = balanced;
        surplus = free - cap.times(daysLeft);
      }
    }
    final usage = Percentage.ratio(spentToday, cap);
    return DailySpendingCap(
      cap: cap,
      spentToday: spentToday,
      reserved: reserved,
      surplus: surplus,
      light: usage == null
          ? (spentToday.isPositive ? TrafficLight.critical : TrafficLight.ok)
          : thresholds.classifyUsage(usage),
    );
  }
}
