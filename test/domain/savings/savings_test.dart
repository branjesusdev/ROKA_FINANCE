import 'package:finance_app/domain/savings/essential_expense_estimator.dart';
import 'package:finance_app/domain/savings/goal_progress_calculator.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/savings/savings_target_evaluator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  group('SavingsTargetEvaluator', () {
    const evaluator = SavingsTargetEvaluator();

    SavingsStatus evaluate(int actual) => evaluator.evaluate(
      income: const Money.pesos(7000000),
      actualSavings: Money.pesos(actual),
      targetRate: const Percentage.whole(10),
    );

    test('meta = 10% del ingreso', () {
      final status = evaluate(500000);
      expect(status.target, const Money.pesos(700000));
      expect(status.achieved, const Percentage.basisPoints(7143));
      expect(status.remaining, const Money.pesos(200000));
      expect(status.light, TrafficLight.warning);
    });

    test('verde al cumplir la meta, sin faltante', () {
      final status = evaluate(800000);
      expect(status.light, TrafficLight.ok);
      expect(status.remaining, Money.zero);
    });

    test('rojo si no hay ahorro', () {
      expect(evaluate(-100000).light, TrafficLight.critical);
      expect(evaluate(0).light, TrafficLight.critical);
    });
  });

  group('GoalProgressCalculator', () {
    const calculator = GoalProgressCalculator();
    final today = DateTime(2026, 10, 2);

    GoalContribution contribution(String goalId, int pesos) => GoalContribution(
      id: 'c-$goalId-$pesos',
      goalId: goalId,
      amount: Money.pesos(pesos),
      date: today,
    );

    SavingsGoal goal({DateTime? targetDate, EmergencyPlan? plan}) =>
        SavingsGoal(
          id: 'g1',
          name: 'Viaje',
          type: GoalType.travel,
          targetAmount: const Money.pesos(3000000),
          targetDate: targetDate,
          emergencyPlan: plan,
        );

    final contributions = [
      contribution('g1', 1000000),
      contribution('g1', 500000),
      contribution('other', 999999),
    ];

    test('suma aportes de la meta y sugiere aporte mensual', () {
      final progress = calculator.calculate(
        goal: goal(targetDate: DateTime(2027, 4)),
        contributions: contributions,
        today: today,
      );
      expect(progress.saved, const Money.pesos(1500000));
      expect(progress.progress, const Percentage.whole(50));
      expect(progress.monthsLeft, 6);
      expect(progress.suggestedMonthly, const Money.pesos(250000));
    });

    test('fecha vencida: sugiere el faltante completo', () {
      final progress = calculator.calculate(
        goal: goal(targetDate: DateTime(2026, 5)),
        contributions: contributions,
        today: today,
      );
      expect(progress.monthsLeft, 0);
      expect(progress.suggestedMonthly, const Money.pesos(1500000));
    });

    test('fondo de emergencia: objetivo = gastos esenciales × meses', () {
      final progress = calculator.calculate(
        goal: goal(
          plan: const EmergencyPlan(
            essentialMonthlyExpenses: Money.pesos(2500000),
            targetMonths: 3,
          ),
        ),
        contributions: contributions,
        today: today,
      );
      expect(progress.target, const Money.pesos(7500000));
      expect(progress.remaining, const Money.pesos(6000000));
      expect(progress.suggestedMonthly, isNull);
    });

    test('meta cumplida', () {
      final progress = calculator.calculate(
        goal: goal(targetDate: DateTime(2027, 4)),
        contributions: [contribution('g1', 3000000)],
        today: today,
      );
      expect(progress.isCompleted, isTrue);
      expect(progress.suggestedMonthly, isNull);
    });
  });

  test('EssentialExpenseEstimator promedia solo gastos esenciales', () {
    final average = const EssentialExpenseEstimator().averageMonthly(
      months: const [YearMonth(2026, 8), YearMonth(2026, 9)],
      transactions: [
        expense(
          2000000,
          date: DateTime(2026, 8, 3),
          nature: ExpenseNature.essential,
        ),
        expense(
          3000000,
          date: DateTime(2026, 9, 3),
          nature: ExpenseNature.essential,
        ),
        expense(
          1000000,
          date: DateTime(2026, 9, 4),
          nature: ExpenseNature.discretionary,
        ),
        expense(
          9000000,
          date: DateTime(2026, 7, 3),
          nature: ExpenseNature.essential,
        ),
      ],
    );
    expect(average, const Money.pesos(2500000));
  });
}
