import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

enum GoalType { emergency, travel, vehicle, housing, investment, custom }

/// Fondo de emergencia: N meses de gastos esenciales.
@immutable
final class EmergencyPlan {
  const new({
    required this.essentialMonthlyExpenses,
    required this.targetMonths,
  });

  final Money essentialMonthlyExpenses;
  final int targetMonths;

  Money get target => essentialMonthlyExpenses.times(targetMonths);

  @override
  bool operator ==(Object other) =>
      other is EmergencyPlan &&
      other.essentialMonthlyExpenses == essentialMonthlyExpenses &&
      other.targetMonths == targetMonths;

  @override
  int get hashCode => Object.hash(essentialMonthlyExpenses, targetMonths);
}

/// Meta de ahorro. Lo ahorrado es la suma de sus `GoalContribution`.
@immutable
final class SavingsGoal {
  const new({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    this.targetDate,
    this.desiredMonthlyContribution,
    this.emergencyPlan,
  });

  final String id;
  final String name;
  final GoalType type;
  final Money targetAmount;
  final DateTime? targetDate;
  final Money? desiredMonthlyContribution;
  final EmergencyPlan? emergencyPlan;

  /// Con plan de emergencia, el objetivo se deriva del plan.
  Money get effectiveTarget => emergencyPlan?.target ?? targetAmount;

  @override
  bool operator ==(Object other) =>
      other is SavingsGoal &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.targetAmount == targetAmount &&
      other.targetDate == targetDate &&
      other.desiredMonthlyContribution == desiredMonthlyContribution &&
      other.emergencyPlan == emergencyPlan;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    targetAmount,
    targetDate,
    desiredMonthlyContribution,
    emergencyPlan,
  );
}

@immutable
final class GoalContribution {
  const new({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
  });

  final String id;
  final String goalId;

  /// Negativo para retiros.
  final Money amount;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is GoalContribution &&
      other.id == id &&
      other.goalId == goalId &&
      other.amount == amount &&
      other.date == date;

  @override
  int get hashCode => Object.hash(id, goalId, amount, date);
}
