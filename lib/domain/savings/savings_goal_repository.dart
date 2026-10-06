import 'package:finance_app/domain/savings/savings_goal.dart';

abstract interface class SavingsGoalRepository {
  Future<void> save(SavingsGoal goal);

  /// Elimina la meta y sus aportes.
  Future<void> delete(String id);

  Future<SavingsGoal?> getById(String id);

  Future<List<SavingsGoal>> getAll();

  Stream<List<SavingsGoal>> watchAll();

  Future<void> addContribution(GoalContribution contribution);

  /// Todos los aportes, o solo los de [goalId]. Fecha descendente.
  Future<List<GoalContribution>> getContributions({String? goalId});

  Stream<List<GoalContribution>> watchContributions();
}
