import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/shared/money.dart';

/// Fijo con su fecha dentro de un ciclo.
final class ScheduledFixed {
  const new({required this.movement, required this.date});

  final FixedMovement movement;
  final DateTime date;
}

final class FixedSchedule {
  const new({required this.due, required this.upcoming});

  /// Ya llegó su día y aún no se registró: registrar ahora.
  final List<ScheduledFixed> due;

  /// Su día llega más adelante en este ciclo.
  final List<ScheduledFixed> upcoming;

  Money get upcomingExpenses => Money.sum(
    upcoming.where((s) => s.movement.isExpense).map((s) => s.movement.amount),
  );

  Money get upcomingIncome => Money.sum(
    upcoming.where((s) => !s.movement.isExpense).map((s) => s.movement.amount),
  );
}

/// Decide qué fijos registrar hoy y cuáles faltan en el ciclo actual.
///
/// Solo mira el ciclo actual: no rellena ciclos anteriores.
final class FixedMovementScheduler {
  const new();

  FixedSchedule schedule({
    required List<FixedMovement> movements,
    required PayCycle cycle,
    required DateTime today,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final due = <ScheduledFixed>[];
    final upcoming = <ScheduledFixed>[];
    for (final movement in movements.where((m) => m.isActive)) {
      final date = cycle.dateForDayOfMonth(movement.dayOfMonth);
      final last = movement.lastPostedOn;
      if (last != null && !last.isBefore(date)) continue;
      final item = ScheduledFixed(movement: movement, date: date);
      (date.isAfter(day) ? upcoming : due).add(item);
    }
    int byDate(ScheduledFixed a, ScheduledFixed b) => a.date.compareTo(b.date);
    return FixedSchedule(
      due: due..sort(byDate),
      upcoming: upcoming..sort(byDate),
    );
  }
}
