import 'package:finance_app/application/advisor/windfall_plan.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/application/dashboard/money_overview.dart';
import 'package:finance_app/application/provisions/provision_use_cases.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/provisions/provision_planner.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';

/// A dónde se puede apartar plata para no gastarla en el día a día.
final class SetAsideTarget {
  const new({
    required this.name,
    required this.suggested,
    required this.remaining,
    required this.reason,
    this.provision,
    this.goal,
  });

  final String name;

  /// Lo que conviene apartar hoy.
  final Money suggested;

  /// Lo que le falta en total (tope del aporte).
  final Money remaining;
  final String reason;

  /// Exactamente uno de los dos.
  final Provision? provision;
  final SavingsGoal? goal;
}

final class SetAsidePlan {
  const new({required this.free, required this.targets});

  /// Libre para gastar hoy (lo que se podría apartar sin tocar lo
  /// reservado).
  final Money free;
  final List<SetAsideTarget> targets;

  Money get suggested => Money.sum(targets.map((t) => t.suggested));

  bool get isEmpty => targets.isEmpty;
}

/// "Si me sobra, lo aparto": primero los pagos del año que faltan este
/// ciclo (ya están descontados del libre: apartarlos solo los protege),
/// luego las metas, con la mitad de lo libre como máximo para que quede
/// para el día a día (o todo lo que sobra del tope parejo del ciclo, si es
/// más).
final class SetAsidePlanner {
  const new();

  /// Parte del dinero libre que se sugiere mover a metas.
  static const freeShareForGoals = Percentage.whole(50);

  SetAsidePlan plan({
    required MoneyOverview overview,
    required ProvisionPlan provisions,
    required List<GoalProgressItem> goals,
  }) {
    final targets = <SetAsideTarget>[
      for (final s in provisions.statuses)
        if (s.pendingThisCycle.isPositive)
          SetAsideTarget(
            name: s.provision.name,
            suggested: s.pendingThisCycle,
            remaining: s.remaining,
            reason: s.isOverdue
                ? 'Ya venció: aparta lo que falta.'
                : 'Lo que toca este ciclo para llegar a tiempo.',
            provision: s.provision,
          ),
    ];
    // Lo que sobra del tope parejo del ciclo puede ir completo a metas.
    final free = overview.free.max(Money.zero);
    var budget = free
        .applyPercentage(freeShareForGoals)
        .max(overview.dayToDaySurplus)
        .min(free);
    final open =
        goals
            .where(
              (g) => !g.progress.isCompleted && g.progress.remaining.isPositive,
            )
            .toList()
          // El fondo de emergencia va primero.
          ..sort(
            (a, b) => (a.goal.type == GoalType.emergency ? 0 : 1).compareTo(
              b.goal.type == GoalType.emergency ? 0 : 1,
            ),
          );
    for (final item in open) {
      final remaining = item.progress.remaining;
      final wanted = (item.progress.suggestedMonthly ?? remaining).min(
        remaining,
      );
      final amount = wanted.min(budget);
      targets.add(
        SetAsideTarget(
          name: item.goal.name,
          suggested: amount,
          remaining: remaining,
          reason: item.goal.type == GoalType.emergency
              ? 'Tu colchón para imprevistos.'
              : 'Avanza en tu meta sin tocar lo del día a día.',
          goal: item.goal,
        ),
      );
      budget -= amount;
    }
    return SetAsidePlan(free: overview.free, targets: targets);
  }
}

/// Aparta de verdad: a un pago del año (movimiento en Apartados) o a una
/// meta (aporte + movimiento de ahorro). Solo lo que el usuario confirma.
final class ApplySetAside {
  const new({required this._provisions, required this._goals});

  final SetAsideForProvision _provisions;
  final ApplyWindfallSlices _goals;

  /// [amounts]: por cada objetivo elegido, cuánto apartar.
  Future<Result<int>> call(List<(SetAsideTarget, Money)> amounts) async {
    if (amounts.any((a) => !a.$2.isPositive)) {
      return const Err(ValidationFailure(ValidationCodes.amountMustBePositive));
    }
    var applied = 0;
    for (final (target, amount) in amounts) {
      final Result<Object?> result;
      if (target.provision case final provision?) {
        result = await _provisions(provision: provision, amount: amount);
      } else {
        result = await _goals([
          WindfallSlice(
            use: target.goal!.type == GoalType.emergency
                ? WindfallUse.emergencyFund
                : WindfallUse.goal,
            amount: amount,
            reason: target.reason,
            label: target.name,
            targetId: target.goal!.id,
          ),
        ]);
      }
      // Lo ya apartado se queda; se avisa del primero que falló.
      if (result case Err(:final failure)) return Err(failure);
      applied++;
    }
    return Ok(applied);
  }
}
