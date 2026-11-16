import 'package:finance_app/application/cycles/reconcile_balance.dart';
import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/cycles/cycle_recount.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/insights/cash_flow_calculator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:meta/meta.dart';

/// Lo gastado en un día y cómo va contra el promedio del ciclo.
@immutable
final class DaySpend {
  const new({required this.total, required this.dayToDay, required this.light});

  /// Todos los gastos del día.
  final Money total;

  /// Solo el gasto del día a día (lo que mide el tope diario).
  final Money dayToDay;

  /// Verde: dentro del promedio del ciclo; ámbar: un poco encima; rojo:
  /// bastante encima.
  final TrafficLight light;
}

/// Movimientos de un ciclo de sueldo con sus totales por categoría: la
/// dona, la lista por categoría y la lista de movimientos salen de aquí,
/// así siempre suman lo mismo.
final class CycleMovements {
  const new({
    required this.cycle,
    required this.transactions,
    required this.cashFlow,
    required this.expenseTotals,
    required this.incomeTotals,
    this.recount,
    this.daySpends = const {},
  });

  final PayCycle cycle;

  /// Del más reciente al más antiguo.
  final List<Transaction> transactions;
  final CashFlow cashFlow;

  /// De mayor a menor.
  final List<CategoryTotal> expenseTotals;
  final List<CategoryTotal> incomeTotals;

  /// Reconteo hecho al llegar el sueldo siguiente; `null` si no se hizo.
  final CycleRecount? recount;

  /// Gasto de cada día con movimientos (fecha sin hora).
  final Map<DateTime, DaySpend> daySpends;

  List<CategoryTotal> totalsOf(TransactionKind kind) =>
      kind == TransactionKind.expense ? expenseTotals : incomeTotals;

  /// Movimientos de un tipo y, si se da, de una categoría.
  List<Transaction> filtered(TransactionKind kind, {String? categoryId}) => [
    for (final t in transactions)
      if (t.kind == kind && (categoryId == null || t.categoryId == categoryId))
        t,
  ];

  /// Lo que queda del ciclo según lo registrado (con ajustes de saldo).
  Money get left =>
      cashFlow.adjustments +
      cashFlow.income -
      cashFlow.expenses -
      cashFlow.savingContributions;

  Money totalOf(TransactionKind kind) =>
      Money.sum(totalsOf(kind).map((t) => t.amount));
}

final class CycleMovementsBuilder {
  const new();

  CycleMovements build({
    required PayCycle cycle,
    required Iterable<Transaction> transactions,
    required List<Category> categories,
  }) {
    final mine = transactions.where((t) => cycle.contains(t.date)).toList()
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });
    final byId = {for (final c in categories) c.id: c};
    final cashFlow = const CashFlowCalculator().calculate(
      mine,
      savingCategoryIds: {
        for (final c in categories)
          if (c.countsAsSaving) c.id,
      },
    );
    return CycleMovements(
      cycle: cycle,
      transactions: mine,
      cashFlow: cashFlow,
      recount: _recount(mine, cashFlow),
      daySpends: _daySpends(mine, categories),
      expenseTotals: CycleSummaryBuilder.categoryTotals(
        mine.where((t) => t.isExpense),
        byId,
      ),
      incomeTotals: CycleSummaryBuilder.categoryTotals(
        mine.where((t) => t.isIncome),
        byId,
      ),
    );
  }

  /// Un día se pasa si su día a día supera el promedio diario del ciclo
  /// (de la primera a la última anotación).
  static const _overFactor = 1.25;

  Map<DateTime, DaySpend> _daySpends(
    List<Transaction> mine,
    List<Category> categories,
  ) {
    final savingIds = {
      for (final c in categories)
        if (c.countsAsSaving) c.id,
    };
    DateTime dayOf(Transaction t) =>
        DateTime(t.date.year, t.date.month, t.date.day);
    final total = <DateTime, Money>{};
    final dayToDay = <DateTime, Money>{};
    for (final t in mine.where((t) => t.isExpense)) {
      final day = dayOf(t);
      total[day] = (total[day] ?? Money.zero) + t.amount;
      if (CycleSummaryBuilder.isDayToDay(t, savingIds)) {
        dayToDay[day] = (dayToDay[day] ?? Money.zero) + t.amount;
      }
    }
    if (total.isEmpty) return const {};
    final days = total.keys.toList()..sort();
    final span = days.last.difference(days.first).inDays + 1;
    final average = Money.sum(dayToDay.values).divide(span);
    return {
      for (final day in days)
        day: DaySpend(
          total: total[day]!,
          dayToDay: dayToDay[day] ?? Money.zero,
          light: _light(dayToDay[day] ?? Money.zero, average),
        ),
    };
  }

  static TrafficLight _light(Money spent, Money average) {
    if (spent <= average) return TrafficLight.ok;
    return spent.cents > average.cents * _overFactor
        ? TrafficLight.critical
        : TrafficLight.warning;
  }

  CycleRecount? _recount(List<Transaction> mine, CashFlow flow) {
    final entries = mine.where(
      (t) => t.description == ReconcileBalance.recountDescription,
    );
    if (entries.isEmpty) return null;
    return CycleRecount(
      difference: Money.sum(
        entries.map((t) => t.isExpense ? -t.amount : t.amount),
      ),
      actualLeft:
          flow.adjustments +
          flow.income -
          flow.expenses -
          flow.savingContributions,
    );
  }
}
