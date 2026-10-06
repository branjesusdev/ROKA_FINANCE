import 'package:drift/drift.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/savings/savings_goal_repository.dart';
import 'package:finance_app/infrastructure/mappers/savings_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftSavingsGoalRepository implements SavingsGoalRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(SavingsGoal goal) => guardStorage(
    'goals.save',
    () => _db.into(_db.savingsGoals).insertOnConflictUpdate(goal.toCompanion()),
  );

  @override
  Future<void> delete(String id) => guardStorage(
    'goals.delete',
    () => (_db.delete(_db.savingsGoals)..where((g) => g.id.equals(id))).go(),
  );

  @override
  Future<SavingsGoal?> getById(String id) =>
      guardStorage('goals.getById', () async {
        final query = _db.select(_db.savingsGoals)
          ..where((g) => g.id.equals(id));
        return (await query.getSingleOrNull())?.toDomain();
      });

  @override
  Future<List<SavingsGoal>> getAll() => guardStorage(
    'goals.getAll',
    () async => _goalsToDomain(await _allGoals().get()),
  );

  @override
  Stream<List<SavingsGoal>> watchAll() => guardStorageStream(
    'goals.watchAll',
    _allGoals().watch().map(_goalsToDomain),
  );

  @override
  Future<void> addContribution(GoalContribution contribution) => guardStorage(
    'goals.addContribution',
    () => _db
        .into(_db.goalContributions)
        .insertOnConflictUpdate(contribution.toCompanion()),
  );

  @override
  Future<List<GoalContribution>> getContributions({String? goalId}) =>
      guardStorage(
        'goals.getContributions',
        () async => _contributionsToDomain(await _contributions(goalId).get()),
      );

  @override
  Stream<List<GoalContribution>> watchContributions() => guardStorageStream(
    'goals.watchContributions',
    _contributions(null).watch().map(_contributionsToDomain),
  );

  SimpleSelectStatement<$SavingsGoalsTable, SavingsGoalRow> _allGoals() =>
      _db.select(_db.savingsGoals)..orderBy([(g) => OrderingTerm.asc(g.name)]);

  SimpleSelectStatement<$GoalContributionsTable, GoalContributionRow>
  _contributions(String? goalId) {
    final query = _db.select(_db.goalContributions)
      ..orderBy([(c) => OrderingTerm.desc(c.date)]);
    if (goalId != null) query.where((c) => c.goalId.equals(goalId));
    return query;
  }

  List<SavingsGoal> _goalsToDomain(List<SavingsGoalRow> rows) =>
      rows.map((row) => row.toDomain()).toList();

  List<GoalContribution> _contributionsToDomain(
    List<GoalContributionRow> rows,
  ) => rows.map((row) => row.toDomain()).toList();
}
