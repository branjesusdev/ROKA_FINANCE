import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/shared/year_month.dart';

abstract interface class BudgetRepository {
  /// Si ya existe una línea para el mismo mes y categoría, reemplaza su
  /// límite (conserva el id existente).
  Future<void> save(BudgetLine line);

  Future<void> delete(String id);

  Future<List<BudgetLine>> getByMonth(YearMonth period);

  Stream<List<BudgetLine>> watchByMonth(YearMonth period);
}
