import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/year_month.dart';

final class GoalProgress {
  const new({
    required this.target,
    required this.saved,
    required this.monthsLeft,
    required this.suggestedMonthly,
  });

  final Money target;
  final Money saved;

  /// Meses hasta la fecha objetivo (0 si ya pasó). `null` sin fecha.
  final int? monthsLeft;

  /// Aporte mensual necesario para llegar a tiempo. `null` sin fecha o si
  /// la meta ya se cumplió.
  final Money? suggestedMonthly;

  Money get remaining => (target - saved).max(Money.zero);
  bool get isCompleted => target.isPositive && saved >= target;

  /// `null` si la meta es cero.
  Percentage? get progress => Percentage.ratio(saved, target);
}

final class GoalProgressCalculator {
  const new();

  GoalProgress calculate({
    required SavingsGoal goal,
    required List<GoalContribution> contributions,
    required DateTime today,
  }) {
    final target = goal.effectiveTarget;
    final saved = Money.sum(
      contributions.where((c) => c.goalId == goal.id).map((c) => c.amount),
    );
    final remaining = (target - saved).max(Money.zero);
    final targetDate = goal.targetDate;

    int? monthsLeft;
    Money? suggested;
    if (targetDate != null) {
      final months = YearMonth.fromDate(today)
          .monthsUntil(YearMonth.fromDate(targetDate));
      monthsLeft = months < 0 ? 0 : months;
      if (remaining.isPositive) {
        suggested = remaining.divide(monthsLeft == 0 ? 1 : monthsLeft);
      }
    }

    return GoalProgress(
      target: target,
      saved: saved,
      monthsLeft: monthsLeft,
      suggestedMonthly: suggested,
    );
  }
}
