import 'package:finance_app/application/insights/category_report.dart';
import 'package:finance_app/application/transactions/description_suggestions.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Con qué se comparó un movimiento al armar su historial.
enum MovementHistoryBasis {
  /// Movimientos con la misma descripción ("Gasolina").
  description,

  /// Toda la categoría (la descripción casi no se repite).
  category,
}

/// "¿En qué mes gasté más en esto?": lo mismo que un movimiento, mes a mes.
final class MovementHistory {
  const new({
    required this.basis,
    required this.months,
    required this.total,
    required this.count,
    this.canGroupByDescription = false,
  });

  final MovementHistoryBasis basis;

  /// La descripción se repite: se puede ver solo eso o toda la categoría.
  final bool canGroupByDescription;

  /// Del más antiguo al actual (el último es el mes en curso).
  final List<CategoryMonth> months;
  final Money total;
  final int count;

  CategoryMonth get current => months.last;

  /// El mes más alto (incluye el actual). `null` sin movimientos.
  CategoryMonth? get peak {
    final withData = months.where((m) => m.count > 0);
    if (withData.isEmpty) return null;
    return withData.reduce((a, b) => b.total > a.total ? b : a);
  }

  /// El mes más bajo con movimientos.
  CategoryMonth? get lowest {
    final withData = months.where((m) => m.count > 0);
    if (withData.isEmpty) return null;
    return withData.reduce((a, b) => b.total < a.total ? b : a);
  }

  /// Promedio de los meses con movimientos.
  Money? get monthlyAverage {
    final withData = months.where((m) => m.count > 0).toList();
    if (withData.isEmpty) return null;
    return Money.sum(withData.map((m) => m.total)).divide(withData.length);
  }

  /// Hay con qué comparar: al menos dos meses con movimientos.
  bool get hasHistory => months.where((m) => m.count > 0).length > 1;

  /// Meses con movimientos.
  int get activeMonths => months.where((m) => m.count > 0).length;

  /// Valor promedio de cada movimiento.
  Money? get averageTicket => count == 0 ? null : total.divide(count);

  /// Este mes frente al promedio de los meses con movimientos (positivo =
  /// por encima). `null` sin promedio.
  Percentage? get currentVsAverage {
    final average = monthlyAverage;
    if (average == null || !average.isPositive) return null;
    return Percentage.ratio(current.total - average, average);
  }

  /// Últimos [trendMonths] meses cerrados frente a los [trendMonths]
  /// anteriores (positivo = subiendo). `null` si alguno de los dos está
  /// vacío.
  Percentage? get trend {
    final closed = months.take(months.length - 1).toList();
    if (closed.length < trendMonths * 2) return null;
    final recent = Money.sum(
      closed.skip(closed.length - trendMonths).map((m) => m.total),
    );
    final before = Money.sum(
      closed
          .skip(closed.length - trendMonths * 2)
          .take(trendMonths)
          .map((m) => m.total),
    );
    if (!before.isPositive || !recent.isPositive) return null;
    return Percentage.ratio(recent - before, before);
  }

  /// Ventana de la tendencia (trimestre contra trimestre).
  static const trendMonths = 3;
}

final class MovementHistoryBuilder {
  const new();

  /// Mínimo de movimientos con la misma descripción para comparar por
  /// descripción y no por categoría.
  static const minDescriptionMatches = 2;

  /// [basis] fuerza la agrupación (p. ej. "toda Alimentación"); sin ella
  /// se usa la descripción si se repite.
  MovementHistory build({
    required Transaction target,
    required Iterable<Transaction> transactions,
    required DateTime today,
    MovementHistoryBasis? basis,
    int months = CategoryReportBuilder.defaultMonths,
  }) {
    final range = CategoryReportBuilder.rangeFor(today, months: months);
    final sameKind = transactions
        .where((t) => t.kind == target.kind && range.contains(t.date))
        .toList();
    final key = _key(target);
    final byDescription = key == null
        ? const <Transaction>[]
        : sameKind.where((t) => _key(t) == key).toList();
    final canGroup = byDescription.length >= minDescriptionMatches;
    final useDescription = canGroup && basis != MovementHistoryBasis.category;
    final mine = useDescription
        ? byDescription
        : sameKind.where((t) => t.categoryId == target.categoryId).toList();

    final byMonth = <YearMonth, List<Transaction>>{};
    for (final t in mine) {
      byMonth.putIfAbsent(YearMonth.fromDate(t.date), () => []).add(t);
    }
    final current = YearMonth.fromDate(today);
    return MovementHistory(
      basis: useDescription
          ? MovementHistoryBasis.description
          : MovementHistoryBasis.category,
      months: [
        for (var i = months - 1; i >= 0; i--)
          if (byMonth[current.addMonths(-i)] ?? const <Transaction>[]
              case final list)
            CategoryMonth(
              month: current.addMonths(-i),
              total: Money.sum(list.map((t) => t.amount)),
              count: list.length,
            ),
      ],
      total: Money.sum(mine.map((t) => t.amount)),
      count: mine.length,
      canGroupByDescription: canGroup,
    );
  }

  static String? _key(Transaction t) {
    final text = t.description?.trim();
    if (text == null || text.isEmpty) return null;
    return DescriptionSuggestions.normalize(text);
  }
}
