import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/savings/savings_goal_repository.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';

/// Cambia el % de ahorro de referencia (5%, 10%, 15%, 20% o personalizado).
final class UpdateSavingsTarget {
  const new(this._settings);

  final SettingsRepository _settings;

  Future<Result<FinanceSettings>> call(Percentage rate) {
    if (rate <= Percentage.zero || rate > Percentage.hundred) {
      return invalid(ValidationCodes.rateOutOfRange);
    }
    return guardUseCase(() async {
      final updated = (await _settings.get()).copyWith(savingsTargetRate: rate);
      await _settings.save(updated);
      return updated;
    });
  }
}

/// Crea (sin `id`) o actualiza una meta. Con `emergencyPlan` el objetivo se
/// calcula como gastos esenciales × meses.
final class SaveGoal {
  const new({required this._goals, required this._ids});

  final SavingsGoalRepository _goals;
  final IdGenerator _ids;

  Future<Result<SavingsGoal>> call({
    required String name,
    required GoalType type,
    required Money targetAmount,
    String? id,
    DateTime? targetDate,
    Money? desiredMonthlyContribution,
    EmergencyPlan? emergencyPlan,
  }) {
    final cleanName = cleanText(name);
    if (cleanName == null) return invalid(ValidationCodes.nameRequired);
    if (emergencyPlan != null && emergencyPlan.targetMonths <= 0) {
      return invalid(ValidationCodes.monthsMustBePositive);
    }
    final target = emergencyPlan?.target ?? targetAmount;
    if (!target.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    final goal = SavingsGoal(
      id: id ?? _ids.next(),
      name: cleanName,
      type: type,
      targetAmount: target,
      targetDate: targetDate,
      desiredMonthlyContribution: desiredMonthlyContribution,
      emergencyPlan: emergencyPlan,
    );
    return guardUseCase(() async {
      await _goals.save(goal);
      return goal;
    });
  }
}

final class DeleteGoal {
  const new(this._goals);

  final SavingsGoalRepository _goals;

  Future<Result<void>> call(String id) => guardUseCase(() => _goals.delete(id));
}

/// Aporte (positivo) o retiro (negativo) de una meta.
final class AddContribution {
  const new({required this._goals, required this._clock, required this._ids});

  final SavingsGoalRepository _goals;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<void>> call({required String goalId, required Money amount}) {
    if (amount.isZero) return invalid(ValidationCodes.amountMustNotBeZero);
    return guardUseCase(
      () => _goals.addContribution(
        GoalContribution(
          id: _ids.next(),
          goalId: goalId,
          amount: amount,
          date: _clock.now(),
        ),
      ),
    );
  }
}
