import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/budgets/budget_repository.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';

/// Define (o reemplaza) el límite mensual de una categoría.
final class SetBudgetLimit {
  const new({required this._budgets, required this._ids});

  final BudgetRepository _budgets;
  final IdGenerator _ids;

  Future<Result<void>> call({
    required YearMonth period,
    required String categoryId,
    required Money limit,
  }) {
    if (!limit.isPositive) return invalid(ValidationCodes.amountMustBePositive);
    return guardUseCase(
      () => _budgets.save(
        BudgetLine(
          id: _ids.next(),
          period: period,
          categoryId: categoryId,
          limit: limit,
        ),
      ),
    );
  }
}

final class RemoveBudgetLimit {
  const new(this._budgets);

  final BudgetRepository _budgets;

  Future<Result<void>> call(String lineId) =>
      guardUseCase(() => _budgets.delete(lineId));
}

/// Copia los límites del mes anterior si el mes aún no tiene presupuesto.
/// Devuelve cuántas líneas se copiaron.
final class CopyPreviousMonthBudget {
  const new({required this._budgets, required this._ids});

  final BudgetRepository _budgets;
  final IdGenerator _ids;

  Future<Result<int>> call(YearMonth period) => guardUseCase(() async {
    if ((await _budgets.getByMonth(period)).isNotEmpty) return 0;
    final previous = await _budgets.getByMonth(period.previous);
    for (final line in previous) {
      await _budgets.save(
        BudgetLine(
          id: _ids.next(),
          period: period,
          categoryId: line.categoryId,
          limit: line.limit,
        ),
      );
    }
    return previous.length;
  });
}
