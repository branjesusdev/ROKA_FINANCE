import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Fijo con su fecha dentro de un ciclo.
final class ScheduledFixed {
  const new({required this.movement, required this.date});

  final FixedMovement movement;
  final DateTime date;
}

final class FixedSchedule {
  const new({
    required this.due,
    required this.upcoming,
    this.covered = const [],
    this.awaitingAmount = const [],
  });

  /// Ya llegó su día y aún no se registró: registrar ahora.
  final List<ScheduledFixed> due;

  /// Su día llega más adelante en este ciclo.
  final List<ScheduledFixed> upcoming;

  /// Ingresos fijos que ya llegaron porque el usuario los anotó a mano
  /// (p. ej. sueldo adelantado): marcar como registrados sin duplicarlos.
  final List<ScheduledFixed> covered;

  /// Fijos de valor variable cuyo día ya llegó: esperan que el usuario
  /// escriba el valor real de la factura.
  final List<ScheduledFixed> awaitingAmount;

  /// Lo que aún falta por salir o entrar en el ciclo: lo que viene y las
  /// facturas sin confirmar (por su estimado).
  List<ScheduledFixed> get pending => [...awaitingAmount, ...upcoming];

  Money get upcomingExpenses => Money.sum(
    pending.where((s) => s.movement.isExpense).map((s) => s.movement.amount),
  );

  Money get upcomingIncome => Money.sum(
    pending.where((s) => !s.movement.isExpense).map((s) => s.movement.amount),
  );

  /// Gastos fijos pendientes por categoría.
  Map<String, Money> get upcomingExpensesByCategory {
    final totals = <String, Money>{};
    for (final s in pending.where((s) => s.movement.isExpense)) {
      totals.update(
        s.movement.categoryId,
        (total) => total + s.movement.amount,
        ifAbsent: () => s.movement.amount,
      );
    }
    return totals;
  }
}

/// Decide qué fijos registrar hoy y cuáles faltan en el ciclo actual.
///
/// Solo mira el ciclo actual: no rellena ciclos anteriores.
final class FixedMovementScheduler {
  const new();

  /// Un ingreso anotado hasta medio mes antes cubre al fijo (sueldo
  /// adelantado). Dos ocurrencias del mismo fijo nunca están tan cerca.
  static const coverWindow = Duration(days: 16);

  /// [cycleTransactions]: movimientos ya registrados en el ciclo. Un ingreso
  /// fijo cuya categoría recibió un ingreso dentro de [coverWindow] antes de
  /// su fecha (o ese mismo día) se da por recibido.
  FixedSchedule schedule({
    required List<FixedMovement> movements,
    required PayCycle cycle,
    required DateTime today,
    List<Transaction> cycleTransactions = const [],
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final due = <ScheduledFixed>[];
    final upcoming = <ScheduledFixed>[];
    final covered = <ScheduledFixed>[];
    final awaiting = <ScheduledFixed>[];
    for (final movement in movements.where((m) => m.isActive)) {
      final last = movement.lastPostedOn;
      for (final date in cycle.datesForDayOfMonth(movement.dayOfMonth)) {
        if (last != null && !last.isBefore(date)) continue;
        final item = ScheduledFixed(movement: movement, date: date);
        final isFuture = date.isAfter(day);
        if (_alreadyReceived(movement, date, cycleTransactions)) {
          if (!isFuture) covered.add(item);
          continue;
        }
        if (isFuture) {
          upcoming.add(item);
        } else {
          (movement.isVariable ? awaiting : due).add(item);
        }
      }
    }
    int byDate(ScheduledFixed a, ScheduledFixed b) => a.date.compareTo(b.date);
    return FixedSchedule(
      due: due..sort(byDate),
      upcoming: upcoming..sort(byDate),
      covered: covered..sort(byDate),
      awaitingAmount: awaiting..sort(byDate),
    );
  }

  bool _alreadyReceived(
    FixedMovement movement,
    DateTime date,
    List<Transaction> transactions,
  ) {
    if (movement.isExpense) return false;
    final from = date.subtract(coverWindow);
    final until = date.add(const Duration(days: 1));
    return transactions.any(
      (t) =>
          t.isIncome &&
          t.categoryId == movement.categoryId &&
          !t.date.isBefore(from) &&
          t.date.isBefore(until),
    );
  }
}
