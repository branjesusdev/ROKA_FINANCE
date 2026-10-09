import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Categoría donde más se fue el dinero.
final class TopCategory {
  const new({
    required this.categoryId,
    required this.amount,
    required this.share,
  });

  final String categoryId;
  final Money amount;
  final Percentage share;
}

/// "Así vas este ciclo": lectura sencilla de tus registros. Solo describe;
/// no aconseja.
final class CyclePulse {
  const new({
    required this.daysElapsed,
    required this.dayToDaySpent,
    required this.daysWithoutSpending,
    required this.daysRegistered,
    this.previousAtSamePoint,
    this.topCategory,
    this.biggestExpense,
    this.busiestWeekday,
  });

  /// Días del ciclo hasta hoy (incluido).
  final int daysElapsed;

  /// Día a día gastado (sin fijos, mercado, ahorro ni cuadres).
  final Money dayToDaySpent;

  /// Lo que llevabas de día a día el ciclo anterior en los mismos días.
  /// `null` si no hay registros del ciclo anterior.
  final Money? previousAtSamePoint;

  /// Días sin gastos del día a día.
  final int daysWithoutSpending;

  /// Días en que anotaste al menos un movimiento.
  final int daysRegistered;

  final TopCategory? topCategory;

  /// Gasto más grande que no viene de un fijo.
  final Transaction? biggestExpense;

  /// Día de la semana (1 = lunes) con más día a día. Solo con dos semanas
  /// de datos o más.
  final int? busiestWeekday;

  bool get isEmpty => daysRegistered == 0;

  Money get averagePerDay =>
      daysElapsed == 0 ? Money.zero : dayToDaySpent.divide(daysElapsed);

  /// Positivo = gastas más que el ciclo pasado a esta altura.
  Money? get changeVsPrevious =>
      previousAtSamePoint == null ? null : dayToDaySpent - previousAtSamePoint!;

  /// Cambio relativo frente al ciclo pasado. `null` sin base.
  Percentage? get changeShare {
    final change = changeVsPrevious;
    if (change == null) return null;
    return Percentage.ratio(change.abs, previousAtSamePoint!);
  }
}

final class CyclePulseBuilder {
  const new();

  /// Días mínimos para hablar del día de la semana.
  static const minDaysForWeekday = 14;

  CyclePulse build({
    required PayCycle cycle,
    required DateTime today,
    required List<Transaction> cycleTransactions,
    required Set<String> savingCategoryIds,
    PayCycle? previousCycle,
    List<Transaction> previousCycleTransactions = const [],
  }) {
    final last = _day(today).isBefore(cycle.lastDay)
        ? _day(today)
        : cycle.lastDay;
    final days = <DateTime>[
      for (
        var d = cycle.start;
        !d.isAfter(last);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        d,
    ];
    bool dayToDay(Transaction t) =>
        CycleSummaryBuilder.isDayToDay(t, savingCategoryIds);
    final byDay = <DateTime, Money>{};
    for (final t in cycleTransactions.where(dayToDay)) {
      byDay.update(_day(t.date), (a) => a + t.amount, ifAbsent: () => t.amount);
    }
    final spent = Money.sum(byDay.values);

    Money? previous;
    if (previousCycle != null && previousCycleTransactions.isNotEmpty) {
      final until = DateTime(
        previousCycle.start.year,
        previousCycle.start.month,
        previousCycle.start.day + days.length,
      );
      previous = Money.sum(
        previousCycleTransactions
            .where((t) => dayToDay(t) && t.date.isBefore(until))
            .map((t) => t.amount),
      );
    }

    final real = cycleTransactions
        .where(
          (t) =>
              t.isExpense &&
              !savingCategoryIds.contains(t.categoryId) &&
              t.categoryId != DefaultCategories.untracked.id,
        )
        .toList();

    return CyclePulse(
      daysElapsed: days.length,
      dayToDaySpent: spent,
      previousAtSamePoint: previous,
      daysWithoutSpending: days
          .where((d) => !(byDay[d]?.isPositive ?? false))
          .length,
      daysRegistered: {
        for (final t in cycleTransactions)
          if (!t.date.isAfter(today)) _day(t.date),
      }.length,
      topCategory: _top(real),
      biggestExpense: _biggest(real.where((t) => t.fixedMovementId == null)),
      busiestWeekday: days.length < minDaysForWeekday
          ? null
          : _busiestWeekday(byDay),
    );
  }

  TopCategory? _top(List<Transaction> expenses) {
    final total = Money.sum(expenses.map((t) => t.amount));
    if (!total.isPositive) return null;
    final amounts = <String, Money>{};
    for (final t in expenses) {
      amounts.update(
        t.categoryId,
        (a) => a + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    final top = amounts.entries.reduce((a, b) => b.value > a.value ? b : a);
    return TopCategory(
      categoryId: top.key,
      amount: top.value,
      share: Percentage.ratio(top.value, total)!,
    );
  }

  Transaction? _biggest(Iterable<Transaction> expenses) => expenses.isEmpty
      ? null
      : expenses.reduce((a, b) => b.amount > a.amount ? b : a);

  int? _busiestWeekday(Map<DateTime, Money> byDay) {
    final totals = <int, Money>{};
    for (final MapEntry(key: day, value: amount) in byDay.entries) {
      totals.update(day.weekday, (a) => a + amount, ifAbsent: () => amount);
    }
    if (totals.isEmpty) return null;
    return totals.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
