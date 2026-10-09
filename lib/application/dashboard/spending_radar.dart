import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Un eje de la araña: lo gastado este ciclo y el anterior en los mismos
/// días.
final class RadarAxis {
  const new({required this.key, required this.current, required this.previous});

  /// Id de categoría o día de la semana (`'1'` = lunes … `'7'` = domingo).
  final String key;
  final Money current;
  final Money previous;

  /// Positivo = más que el ciclo pasado a esta altura.
  Money get change => current - previous;

  /// Cambio relativo. `null` si el ciclo pasado no tuvo gasto en este eje.
  Percentage? get changeShare => Percentage.ratio(change.abs, previous);
}

/// "Tu huella de gasto": la forma de tus gastos variables (sin fijos ni
/// ahorro) comparada con el ciclo pasado a la misma altura. Dos lecturas:
/// en qué se va (categorías) y cuándo se va (días de la semana).
/// Solo describe; no aconseja.
final class SpendingRadar {
  const new({
    required this.byCategory,
    required this.byWeekday,
    required this.daysElapsed,
    required this.hasPrevious,
  });

  static const empty = SpendingRadar(
    byCategory: [],
    byWeekday: [],
    daysElapsed: 0,
    hasPrevious: false,
  );

  /// Categorías con más gasto (en cualquiera de los dos ciclos). Vacío si
  /// hay menos de [SpendingRadarBuilder.minAxes].
  final List<RadarAxis> byCategory;

  /// Siempre 7 ejes (lunes a domingo) o vacío si no hay gastos.
  final List<RadarAxis> byWeekday;

  final int daysElapsed;

  /// Hay registros del ciclo pasado para comparar.
  final bool hasPrevious;

  bool get isEmpty => byCategory.isEmpty && byWeekday.isEmpty;

  /// Eje que más creció (en dinero) frente al ciclo pasado.
  static RadarAxis? biggestRise(List<RadarAxis> axes) =>
      _extreme(axes, (a, b) => b.change > a.change, (a) => a.change.isPositive);

  /// Eje que más bajó (en dinero) frente al ciclo pasado.
  static RadarAxis? biggestDrop(List<RadarAxis> axes) =>
      _extreme(axes, (a, b) => b.change < a.change, (a) => a.change.isNegative);

  /// Eje con más gasto este ciclo.
  static RadarAxis? strongest(List<RadarAxis> axes) => _extreme(
    axes,
    (a, b) => b.current > a.current,
    (a) => a.current.isPositive,
  );

  static RadarAxis? _extreme(
    List<RadarAxis> axes,
    bool Function(RadarAxis a, RadarAxis b) better,
    bool Function(RadarAxis a) valid,
  ) {
    final candidates = axes.where(valid);
    if (candidates.isEmpty) return null;
    return candidates.reduce((a, b) => better(a, b) ? b : a);
  }
}

final class SpendingRadarBuilder {
  const new();

  /// Una araña necesita al menos 3 ejes para tener forma.
  static const minAxes = 3;

  /// Más ejes no se leen bien en un teléfono.
  static const maxCategoryAxes = 6;

  static const _daysInWeek = 7;

  SpendingRadar build({
    required PayCycle cycle,
    required DateTime today,
    required List<Transaction> cycleTransactions,
    required Set<String> savingCategoryIds,
    PayCycle? previousCycle,
    List<Transaction> previousCycleTransactions = const [],
  }) {
    final todayDay = DateTime(today.year, today.month, today.day);
    final last = todayDay.isBefore(cycle.lastDay) ? todayDay : cycle.lastDay;
    final daysElapsed = last.difference(cycle.start).inDays + 1;
    if (daysElapsed <= 0) return SpendingRadar.empty;

    bool variable(Transaction t) =>
        t.isExpense &&
        t.fixedMovementId == null &&
        !savingCategoryIds.contains(t.categoryId) &&
        t.categoryId != DefaultCategories.untracked.id &&
        t.categoryId != DefaultCategories.debtsId;

    final current = cycleTransactions
        .where((t) => variable(t) && t.date.isBefore(_nextDay(last)))
        .toList();
    var previous = const <Transaction>[];
    if (previousCycle != null) {
      final until = DateTime(
        previousCycle.start.year,
        previousCycle.start.month,
        previousCycle.start.day + daysElapsed,
      );
      previous = previousCycleTransactions
          .where((t) => variable(t) && t.date.isBefore(until))
          .toList();
    }
    if (current.isEmpty && previous.isEmpty) return SpendingRadar.empty;

    final byCategory = _axes(current, previous, (t) => t.categoryId)
      ..sort((a, b) => _peak(b).compareTo(_peak(a)));
    final topCategories = byCategory.take(maxCategoryAxes).toList();

    final weekdays = {
      for (final axis in _axes(current, previous, (t) => '${t.date.weekday}'))
        axis.key: axis,
    };

    return SpendingRadar(
      byCategory: topCategories.length < minAxes ? const [] : topCategories,
      byWeekday: [
        for (var d = DateTime.monday; d <= _daysInWeek; d++)
          weekdays['$d'] ??
              RadarAxis(key: '$d', current: Money.zero, previous: Money.zero),
      ],
      daysElapsed: daysElapsed,
      hasPrevious: previous.isNotEmpty,
    );
  }

  static List<RadarAxis> _axes(
    List<Transaction> current,
    List<Transaction> previous,
    String Function(Transaction t) keyOf,
  ) {
    Map<String, Money> sum(List<Transaction> transactions) {
      final totals = <String, Money>{};
      for (final t in transactions) {
        totals.update(keyOf(t), (a) => a + t.amount, ifAbsent: () => t.amount);
      }
      return totals;
    }

    final now = sum(current);
    final before = sum(previous);
    return [
      for (final key in {...now.keys, ...before.keys})
        RadarAxis(
          key: key,
          current: now[key] ?? Money.zero,
          previous: before[key] ?? Money.zero,
        ),
    ];
  }

  static Money _peak(RadarAxis axis) =>
      axis.current > axis.previous ? axis.current : axis.previous;

  static DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);
}
