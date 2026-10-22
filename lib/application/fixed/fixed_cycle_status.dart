import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/fixed/fixed_coverage.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
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

/// Conteo completo de los fijos del ciclo para la cabecera de "Fijos del
/// mes": cuánto suman, cuánto va pagado y en qué categorías se concentra.
final class FixedCycleOverview {
  const new({
    required this.expenseTotal,
    required this.paid,
    required this.pending,
    required this.overdue,
    required this.paidCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.pausedCount,
    required this.incomeTotal,
    required this.byCategory,
  });

  /// Gastos fijos que tocan este ciclo (pagados + por pagar).
  final Money expenseTotal;
  final Money paid;

  /// Por pagar, incluidos los vencidos.
  final Money pending;
  final Money overdue;
  final int paidCount;

  /// Por pagar, incluidos los vencidos.
  final int pendingCount;
  final int overdueCount;
  final int pausedCount;

  /// Ingresos fijos del ciclo (recibidos + por llegar).
  final Money incomeTotal;

  /// Gastos fijos del ciclo por categoría, de mayor a menor.
  final List<CategoryTotal> byCategory;

  int get expenseCount => paidCount + pendingCount;

  /// Parte de los gastos fijos que ya se pagó; `null` si no hay.
  Percentage? get paidShare => Percentage.ratio(paid, expenseTotal);

  /// Ingresos fijos − gastos fijos.
  Money get net => incomeTotal - expenseTotal;
}

final class FixedCycleOverviewBuilder {
  const new();

  FixedCycleOverview build({
    required List<FixedCycleStatus> statuses,
    required Map<String, Category> categories,
  }) {
    final expenses = statuses.where((s) => s.movement.isExpense);
    final paid = expenses.where((s) => s.isDone).toList();
    final pending = expenses.where((s) => s.isPending).toList();
    final overdue = pending
        .where((s) => s.state == FixedCycleState.overdue)
        .toList();
    Money total(Iterable<FixedCycleStatus> list) =>
        Money.sum(list.map((s) => s.movement.amount));
    final inCycle = [...paid, ...pending];
    final amounts = <String, Money>{};
    final counts = <String, int>{};
    for (final s in inCycle) {
      final id = s.movement.categoryId;
      amounts.update(
        id,
        (a) => a + s.movement.amount,
        ifAbsent: () => s.movement.amount,
      );
      counts.update(id, (c) => c + 1, ifAbsent: () => 1);
    }
    final expenseTotal = total(inCycle);
    return FixedCycleOverview(
      expenseTotal: expenseTotal,
      paid: total(paid),
      pending: total(pending),
      overdue: total(overdue),
      paidCount: paid.length,
      pendingCount: pending.length,
      overdueCount: overdue.length,
      pausedCount: statuses
          .where((s) => s.state == FixedCycleState.paused)
          .length,
      incomeTotal: total(
        statuses.where(
          (s) => !s.movement.isExpense && (s.isDone || s.isPending),
        ),
      ),
      byCategory: [
        for (final MapEntry(key: id, value: amount) in amounts.entries)
          CategoryTotal(
            categoryId: id,
            category: categories[id],
            amount: amount,
            share: Percentage.ratio(amount, expenseTotal) ?? Percentage.zero,
            count: counts[id]!,
          ),
      ]..sort((a, b) => b.amount.compareTo(a.amount)),
    );
  }
}
