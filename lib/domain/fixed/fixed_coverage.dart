import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Estado de un pago fijo dentro del ciclo.
enum ObligationState {
  /// Ya se registró el pago en este ciclo.
  paid,

  /// Su día pasó y espera el valor real (factura variable sin confirmar).
  overdue,

  /// Lo que tienes alcanza para pagarlo completo.
  covered,

  /// Alcanza solo una parte.
  partial,

  /// No alcanza: hay que conseguir o recortar.
  uncovered,
}

/// Un gasto fijo del ciclo con cuánto del dinero actual le corresponde.
final class ObligationCoverage {
  const new({
    required this.movement,
    required this.date,
    required this.amount,
    required this.reserved,
    required this.state,
  });

  final FixedMovement movement;
  final DateTime date;
  final Money amount;

  /// Parte del dinero del ciclo que ya le alcanza (asignación, no un
  /// movimiento real).
  final Money reserved;
  final ObligationState state;

  Money get missing => (amount - reserved).max(Money.zero);

  Percentage get progress =>
      Percentage.ratio(reserved, amount) ?? Percentage.hundred;
}

/// Los gastos fijos del ciclo y cuánto de ellos ya está cubierto.
final class CoveragePlan {
  const new({required this.items});

  static const empty = CoveragePlan(items: []);

  /// Pagados primero; luego los pendientes por fecha.
  final List<ObligationCoverage> items;

  Iterable<ObligationCoverage> get pending =>
      items.where((i) => i.state != ObligationState.paid);

  /// Dinero comprometido: lo que falta pagar de los fijos.
  Money get committed => Money.sum(pending.map((i) => i.amount));

  /// Lo que falta para cubrir todos los fijos pendientes.
  Money get missing => Money.sum(pending.map((i) => i.missing));
}

/// Reparte el dinero disponible del ciclo entre los gastos fijos que faltan,
/// del más cercano al más lejano (primero lo que vence primero).
///
/// Las facturas vencidas sin confirmar van de primeras: son las más
/// urgentes.
final class FixedCoverageCalculator {
  const new();

  CoveragePlan calculate({
    required FixedSchedule schedule,
    required List<FixedMovement> movements,
    required List<Transaction> cycleTransactions,
    required Money available,
  }) {
    final paid = <ObligationCoverage>[];
    final seen = <String>{};
    for (final t in cycleTransactions) {
      final id = t.fixedMovementId;
      if (id == null || !t.isExpense || !seen.add('$id-${t.id}')) continue;
      final movement = movements.where((m) => m.id == id).firstOrNull;
      if (movement == null) continue;
      paid.add(
        ObligationCoverage(
          movement: movement,
          date: t.date,
          amount: t.amount,
          reserved: t.amount,
          state: ObligationState.paid,
        ),
      );
    }
    var left = available.max(Money.zero);
    final pending = <ObligationCoverage>[];
    final queue = [
      for (final s in schedule.awaitingAmount)
        if (s.movement.isExpense) (s, true),
      for (final s in schedule.upcoming)
        if (s.movement.isExpense) (s, false),
    ];
    for (final (item, overdue) in queue) {
      final amount = item.movement.amount;
      final reserved = amount.min(left);
      left -= reserved;
      pending.add(
        ObligationCoverage(
          movement: item.movement,
          date: item.date,
          amount: amount,
          reserved: reserved,
          state: overdue
              ? ObligationState.overdue
              : reserved >= amount
              ? ObligationState.covered
              : reserved.isPositive
              ? ObligationState.partial
              : ObligationState.uncovered,
        ),
      );
    }
    paid.sort((a, b) => a.date.compareTo(b.date));
    return CoveragePlan(items: [...paid, ...pending]);
  }
}
