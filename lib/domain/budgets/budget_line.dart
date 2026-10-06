import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:meta/meta.dart';

/// Límite de gasto de una categoría en un mes. Única por (mes, categoría).
@immutable
final class BudgetLine {
  const new({
    required this.id,
    required this.period,
    required this.categoryId,
    required this.limit,
  });

  final String id;
  final YearMonth period;
  final String categoryId;
  final Money limit;

  @override
  bool operator ==(Object other) =>
      other is BudgetLine &&
      other.id == id &&
      other.period == period &&
      other.categoryId == categoryId &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(id, period, categoryId, limit);
}
