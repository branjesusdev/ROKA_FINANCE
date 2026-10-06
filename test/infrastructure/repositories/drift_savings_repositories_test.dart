import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/drift_savings_goal_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());

  group('DriftSavingsGoalRepository', () {
    late DriftSavingsGoalRepository repository;

    final emergency = SavingsGoal(
      id: 'g1',
      name: 'Fondo de emergencia',
      type: GoalType.emergency,
      targetAmount: const Money.pesos(7500000),
      targetDate: DateTime(2027, 6),
      desiredMonthlyContribution: const Money.pesos(500000),
      emergencyPlan: const EmergencyPlan(
        essentialMonthlyExpenses: Money.pesos(2500000),
        targetMonths: 3,
      ),
    );

    GoalContribution contribution(String id, String goalId, int day) =>
        GoalContribution(
          id: id,
          goalId: goalId,
          amount: const Money.pesos(100000),
          date: DateTime(2026, 9, day),
        );

    setUp(() => repository = DriftSavingsGoalRepository(db));

    test('guarda y recupera una meta con plan de emergencia', () async {
      await repository.save(emergency);

      expect(await repository.getById('g1'), emergency);
    });

    test('filtra aportes por meta y borra en cascada', () async {
      const travel = SavingsGoal(
        id: 'g2',
        name: 'Viaje',
        type: GoalType.travel,
        targetAmount: Money.pesos(3000000),
      );
      await repository.save(emergency);
      await repository.save(travel);
      await repository.addContribution(contribution('c1', 'g1', 1));
      await repository.addContribution(contribution('c2', 'g1', 15));
      await repository.addContribution(contribution('c3', 'g2', 10));

      final ofEmergency = await repository.getContributions(goalId: 'g1');
      expect(ofEmergency.map((c) => c.id), ['c2', 'c1']);

      await repository.delete('g1');
      final remaining = await repository.getContributions();
      expect(remaining.map((c) => c.id), ['c3']);
    });
  });

  group('DriftSettingsRepository', () {
    test('guarda y observa la configuración', () async {
      final repository = DriftSettingsRepository(db);
      const custom = FinanceSettings(
        savingsTargetRate: Percentage.whole(15),
        thresholds: TrafficLightThresholds(
          warningFrom: Percentage.whole(70),
          criticalAbove: Percentage.whole(95),
        ),
        smallExpenseThreshold: Money.pesos(30000),
      );

      final expectation = expectLater(
        repository.watch(),
        emitsInOrder([const FinanceSettings(), custom]),
      );
      await pumpEventQueue();
      await repository.save(custom);
      await expectation;

      expect(await repository.get(), custom);
    });
  });
}
