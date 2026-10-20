import 'package:finance_app/domain/fixed/fixed_coverage.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// En qué va un fijo dentro del ciclo de sueldo actual.
enum FixedCycleState {
  /// Gasto ya pagado (registrado) en este ciclo.
  paid,

  /// Ingreso que ya llegó en este ciclo.
  received,

  /// Su día pasó y espera el valor real (factura variable).
  overdue,

  /// Falta: su día llega más adelante en el ciclo.
  upcoming,

  /// Pausado: no se registra.
  paused,

  /// No le toca en este ciclo.
  notThisCycle,
}

final class FixedCycleStatus {
  const new({
    required this.movement,
    required this.state,
    this.date,
    this.coverage,
  });

  final FixedMovement movement;
  final FixedCycleState state;

  /// Cuándo se pagó / recibió, o cuándo vence.
  final DateTime? date;

  /// Para gastos que faltan: si lo que tienes alcanza.
  final ObligationState? coverage;

  bool get isPending =>
      state == FixedCycleState.upcoming || state == FixedCycleState.overdue;

  bool get isDone =>
      state == FixedCycleState.paid || state == FixedCycleState.received;
}

/// Une el calendario de fijos, las reservas y lo ya registrado en el ciclo
/// para decir de cada fijo si ya pasó (pagado) o si viene (por pagar).
final class FixedCycleStatusBuilder {
  const new();

  /// Por pagar primero (por fecha), luego lo ya pagado y al final el resto.
  List<FixedCycleStatus> build({
    required List<FixedMovement> movements,
    required FixedSchedule schedule,
    required CoveragePlan coverage,
    required List<Transaction> cycleTransactions,
  }) {
    final statuses = [
      for (final m in movements)
        _status(m, schedule, coverage, cycleTransactions),
    ];
    int rank(FixedCycleStatus s) => switch (s.state) {
      FixedCycleState.overdue => 0,
      FixedCycleState.upcoming => 1,
      FixedCycleState.paid || FixedCycleState.received => 2,
      FixedCycleState.notThisCycle => 3,
      FixedCycleState.paused => 4,
    };
    return statuses..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      final ad = a.date;
      final bd = b.date;
      if (ad == null || bd == null) {
        return a.movement.dayOfMonth.compareTo(b.movement.dayOfMonth);
      }
      return ad.compareTo(bd);
    });
  }

  FixedCycleStatus _status(
    FixedMovement movement,
    FixedSchedule schedule,
    CoveragePlan coverage,
    List<Transaction> transactions,
  ) {
    if (!movement.isActive) {
      return FixedCycleStatus(
        movement: movement,
        state: FixedCycleState.paused,
      );
    }
    bool mine(ScheduledFixed s) => s.movement.id == movement.id;
    final awaiting = schedule.awaitingAmount.where(mine).firstOrNull;
    if (awaiting != null) {
      return FixedCycleStatus(
        movement: movement,
        state: FixedCycleState.overdue,
        date: awaiting.date,
        coverage: ObligationState.overdue,
      );
    }
    final posted = transactions
        .where((t) => t.fixedMovementId == movement.id)
        .map((t) => t.date)
        .toList();
    final next = [
      // Vencido pero ya anotado (p. ej. pagado a mano): cuenta como pagado.
      if (posted.isEmpty) ...schedule.due.where(mine),
      ...schedule.upcoming.where(mine),
    ].firstOrNull;
    if (next != null) {
      final item = coverage.pending
          .where((i) => i.movement.id == movement.id)
          .firstOrNull;
      return FixedCycleStatus(
        movement: movement,
        state: FixedCycleState.upcoming,
        date: next.date,
        coverage: movement.isExpense ? item?.state : null,
      );
    }
    final received = schedule.covered.where(mine).map((s) => s.date);
    final done = [...posted, ...received]..sort();
    if (done.isNotEmpty) {
      return FixedCycleStatus(
        movement: movement,
        state: movement.isExpense
            ? FixedCycleState.paid
            : FixedCycleState.received,
        date: done.last,
      );
    }
    return FixedCycleStatus(
      movement: movement,
      state: FixedCycleState.notThisCycle,
    );
  }
}
