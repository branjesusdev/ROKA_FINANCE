import 'package:drift/drift.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';

extension SavingsGoalRowMapper on SavingsGoalRow {
  SavingsGoal toDomain() {
    final essential = essentialMonthlyCents;
    final months = emergencyTargetMonths;
    final desired = desiredMonthlyCents;
    return SavingsGoal(
      id: id,
      name: name,
      type: type,
      targetAmount: Money(targetAmountCents),
      targetDate: targetDate,
      desiredMonthlyContribution: desired == null ? null : Money(desired),
      emergencyPlan: essential == null || months == null
          ? null
          : EmergencyPlan(
              essentialMonthlyExpenses: Money(essential),
              targetMonths: months,
            ),
    );
  }
}

extension SavingsGoalCompanionMapper on SavingsGoal {
  SavingsGoalsCompanion toCompanion() => SavingsGoalsCompanion.insert(
    id: id,
    name: name,
    type: type,
    targetAmountCents: targetAmount.cents,
    targetDate: Value(targetDate),
    desiredMonthlyCents: Value(desiredMonthlyContribution?.cents),
    essentialMonthlyCents: Value(emergencyPlan?.essentialMonthlyExpenses.cents),
    emergencyTargetMonths: Value(emergencyPlan?.targetMonths),
  );
}

extension GoalContributionRowMapper on GoalContributionRow {
  GoalContribution toDomain() => GoalContribution(
    id: id,
    goalId: goalId,
    amount: Money(amountCents),
    date: date,
  );
}

extension GoalContributionCompanionMapper on GoalContribution {
  GoalContributionsCompanion toCompanion() => GoalContributionsCompanion.insert(
    id: id,
    goalId: goalId,
    amountCents: amount.cents,
    date: date,
  );
}
