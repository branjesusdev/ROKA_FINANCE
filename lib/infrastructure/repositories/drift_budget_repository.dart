import 'package:drift/drift.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/budgets/budget_repository.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/infrastructure/mappers/budget_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftBudgetRepository implements BudgetRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(BudgetLine line) => guardStorage(
    'budgets.save',
    () => _db.transaction(() async {
      final existing =
          await (_db.select(_db.budgetLines)..where(
                (b) =>
                    b.year.equals(line.period.year) &
                    b.month.equals(line.period.month) &
                    b.categoryId.equals(line.categoryId),
              ))
              .getSingleOrNull();
      if (existing == null) {
        await _db
            .into(_db.budgetLines)
            .insertOnConflictUpdate(line.toCompanion());
      } else {
        await (_db.update(_db.budgetLines)
              ..where((b) => b.id.equals(existing.id)))
            .write(BudgetLinesCompanion(limitCents: Value(line.limit.cents)));
      }
    }),
  );

  @override
  Future<void> delete(String id) => guardStorage(
    'budgets.delete',
    () => (_db.delete(_db.budgetLines)..where((b) => b.id.equals(id))).go(),
  );

  @override
  Future<List<BudgetLine>> getByMonth(YearMonth period) => guardStorage(
    'budgets.getByMonth',
    () async => _toDomain(await _byMonth(period).get()),
  );

  @override
  Stream<List<BudgetLine>> watchByMonth(YearMonth period) => guardStorageStream(
    'budgets.watchByMonth',
    _byMonth(period).watch().map(_toDomain),
  );

  SimpleSelectStatement<$BudgetLinesTable, BudgetLineRow> _byMonth(
    YearMonth period,
  ) => _db.select(_db.budgetLines)
    ..where((b) => b.year.equals(period.year) & b.month.equals(period.month));

  List<BudgetLine> _toDomain(List<BudgetLineRow> rows) =>
      rows.map((row) => row.toDomain()).toList();
}
