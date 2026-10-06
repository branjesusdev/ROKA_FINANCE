import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';

extension BudgetLineRowMapper on BudgetLineRow {
  BudgetLine toDomain() => BudgetLine(
    id: id,
    period: YearMonth(year, month),
    categoryId: categoryId,
    limit: Money(limitCents),
  );
}

extension BudgetLineCompanionMapper on BudgetLine {
  BudgetLinesCompanion toCompanion() => BudgetLinesCompanion.insert(
    id: id,
    year: period.year,
    month: period.month,
    categoryId: categoryId,
    limitCents: limit.cents,
  );
}
