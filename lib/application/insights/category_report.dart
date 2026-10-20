import 'package:finance_app/application/transactions/description_suggestions.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/shared/date_range.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/fuel_economy.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Lo de una categoría en un mes.
final class CategoryMonth {
  const new({required this.month, required this.total, required this.count});

  final YearMonth month;
  final Money total;
  final int count;
}

/// Una cosa que compras seguido dentro de la categoría (por descripción).
final class CategoryItem {
  const new({
    required this.name,
    required this.total,
    required this.count,
    required this.share,
  });

  /// `null` = movimientos sin descripción.
  final String? name;
  final Money total;
  final int count;

  /// Parte del total de la categoría en el periodo.
  final Percentage? share;

  Money get average => total.divide(count);
}

/// Análisis de una sola categoría (p. ej. Mercado): en qué mes gastaste
/// más, en qué cosas y cómo va este mes frente a tu promedio.
final class CategoryReport {
  const new({
    required this.category,
    required this.months,
    required this.items,
    required this.total,
    required this.count,
    this.biggest,
    this.fuel,
  });

  final Category category;

  /// Del más antiguo al actual (el último es el mes en curso).
  final List<CategoryMonth> months;

  /// Lo que más pesa, de mayor a menor.
  final List<CategoryItem> items;
  final Money total;
  final int count;

  /// La compra más grande del periodo.
  final Transaction? biggest;

  /// Solo en categorías de vehículo con kilometraje anotado.
  final FuelEconomy? fuel;

  bool get isEmpty => count == 0;

  CategoryMonth get current => months.last;

  /// Meses cerrados (sin el actual) con algún movimiento.
  List<CategoryMonth> get _closed =>
      months.take(months.length - 1).where((m) => m.count > 0).toList();

  /// El mes en que más gastaste (incluye el actual).
  CategoryMonth? get peak {
    final withData = months.where((m) => m.count > 0);
    if (withData.isEmpty) return null;
    return withData.reduce((a, b) => b.total > a.total ? b : a);
  }

  /// Promedio de los meses cerrados con gasto.
  Money? get monthlyAverage {
    final closed = _closed;
    if (closed.isEmpty) return null;
    return Money.sum(closed.map((m) => m.total)).divide(closed.length);
  }

  /// Este mes frente al promedio (positivo = vas por encima).
  Percentage? get currentVsAverage {
    final average = monthlyAverage;
    if (average == null || !average.isPositive) return null;
    return Percentage.ratio(current.total - average, average);
  }

  /// Valor promedio por compra.
  Money? get averageTicket => count == 0 ? null : total.divide(count);
}

final class CategoryReportBuilder {
  const new();

  /// Meses que se analizan (incluye el actual).
  static const defaultMonths = 12;
  static const maxItems = 6;

  /// Rango a consultar para [build].
  static DateRange rangeFor(DateTime today, {int months = defaultMonths}) {
    final current = YearMonth.fromDate(today);
    final first = current.addMonths(1 - months);
    return DateRange(first.range.start, current.range.endExclusive);
  }

  CategoryReport build({
    required Category category,
    required Iterable<Transaction> transactions,
    required DateTime today,
    int months = defaultMonths,
  }) {
    final kind = category.kind == CategoryKind.income
        ? TransactionKind.income
        : TransactionKind.expense;
    final range = rangeFor(today, months: months);
    final mine = transactions
        .where(
          (t) =>
              t.categoryId == category.id &&
              t.kind == kind &&
              range.contains(t.date),
        )
        .toList();
    final current = YearMonth.fromDate(today);
    final byMonth = <YearMonth, List<Transaction>>{};
    for (final t in mine) {
      byMonth.putIfAbsent(YearMonth.fromDate(t.date), () => []).add(t);
    }
    final total = Money.sum(mine.map((t) => t.amount));

    final groups = <String, ({String? name, List<Transaction> items})>{};
    for (final t in mine) {
      final text = t.description?.trim();
      final name = text == null || text.isEmpty ? null : text;
      final key = name == null ? '' : DescriptionSuggestions.normalize(name);
      groups.putIfAbsent(key, () => (name: name, items: [])).items.add(t);
    }
    final items = [
      for (final g in groups.values)
        if (Money.sum(g.items.map((t) => t.amount)) case final sum)
          CategoryItem(
            name: g.name,
            total: sum,
            count: g.items.length,
            share: Percentage.ratio(sum, total),
          ),
    ]..sort((a, b) => b.total.compareTo(a.total));

    return CategoryReport(
      category: category,
      months: [
        for (var i = months - 1; i >= 0; i--)
          () {
            final month = current.addMonths(-i);
            final list = byMonth[month] ?? const <Transaction>[];
            return CategoryMonth(
              month: month,
              total: Money.sum(list.map((t) => t.amount)),
              count: list.length,
            );
          }(),
      ],
      items: items.take(maxItems).toList(),
      total: total,
      count: mine.length,
      biggest: mine.isEmpty
          ? null
          : mine.reduce((a, b) => b.amount > a.amount ? b : a),
      fuel: FuelEconomyCalculator.appliesTo(category)
          ? const FuelEconomyCalculator().compute(mine)
          : null,
    );
  }
}
