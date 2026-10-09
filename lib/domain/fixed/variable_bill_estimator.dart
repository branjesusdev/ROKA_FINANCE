import 'package:finance_app/domain/shared/money.dart';

/// Estimado de un fijo de valor variable (agua, luz, internet…): promedio
/// de las últimas facturas, redondeado al peso hacia arriba para no
/// quedarse corto.
final class VariableBillEstimator {
  const new();

  /// Facturas que entran en el promedio.
  static const lastBills = 3;

  /// [recent]: valores reales, del más reciente al más antiguo. `null` si no
  /// hay ninguno.
  Money? estimate(List<Money> recent) {
    final bills = recent.take(lastBills).toList();
    if (bills.isEmpty) return null;
    return Money.sum(bills).divideUp(bills.length);
  }
}
