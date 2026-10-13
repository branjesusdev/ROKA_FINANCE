import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';

/// Reconoce si un gasto anotado a mano es en realidad un pago fijo que aún
/// no se ha registrado (p. ej. pagaste el arriendo antes de su día). Así la
/// app pregunta antes de contarlo dos veces.
final class FixedPaymentMatcher {
  const new();

  /// Diferencia máxima con el valor del fijo para considerarlo el mismo.
  static const tolerance = Percentage.whole(20);

  /// Las facturas variables cambian más.
  static const variableTolerance = Percentage.whole(50);

  /// El pendiente más cercano de la misma categoría y valor parecido.
  ScheduledFixed? match({
    required FixedSchedule schedule,
    required String categoryId,
    required Money amount,
  }) {
    final candidates =
        [
            ...schedule.due,
            ...schedule.awaitingAmount,
            ...schedule.upcoming,
          ].where((s) {
            final movement = s.movement;
            if (!movement.isExpense || movement.categoryId != categoryId) {
              return false;
            }
            final limit = movement.amount.applyPercentage(
              movement.isVariable ? variableTolerance : tolerance,
            );
            return (amount - movement.amount).abs <= limit;
          }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return candidates.firstOrNull;
  }
}
