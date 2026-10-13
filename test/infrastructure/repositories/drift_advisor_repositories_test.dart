import 'package:finance_app/application/advisor/windfall_plan.dart';
import 'package:finance_app/application/wealth/record_net_worth.dart';
import 'package:finance_app/domain/advisor/ai_review.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/infrastructure/repositories/drift_ai_key_store.dart';
import 'package:finance_app/infrastructure/repositories/drift_ai_review_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_asset_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_debt_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_investment_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_net_worth_history_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_savings_goal_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_database.dart';

void main() {
  test('la llave se guarda, se reemplaza y se borra', () async {
    final store = DriftAiKeyStore(createTestDatabase());
    expect(await store.read(), isNull);

    await store.save('  gsk_uno ');
    expect(await store.read(), 'gsk_uno');
    await store.save('gsk_dos');
    expect(await store.read(), 'gsk_dos');
    await store.save('');
    expect(await store.read(), isNull);
  });

  test('las revisiones guardan todo y se conservan las últimas', () async {
    final repo = DriftAiReviewRepository(createTestDatabase());
    for (var i = 0; i < DriftAiReviewRepository.keep + 2; i++) {
      await repo.save(
        AiReview(
          id: 'r$i',
          createdAt: DateTime(2026).add(Duration(days: i)),
          headline: 'Revisión $i',
          recommendations: const [
            AiRecommendation(
              title: 'Abona',
              priority: AdvicePriority.high,
              why: 'Tasa alta',
              action: 'Abona 100.000',
              risks: 'Menos liquidez',
            ),
          ],
          missingData: const ['Tasa'],
        ),
      );
    }

    final latest = await repo.latest();
    expect(latest?.id, 'r${DriftAiReviewRepository.keep + 1}');
    expect(latest?.top?.risks, 'Menos liquidez');
    expect(latest?.missingData, ['Tasa']);
  });

  test(
    'una foto de patrimonio por mes; un crédito no se cuenta dos veces',
    () async {
      final db = createTestDatabase();
      final history = DriftNetWorthHistoryRepository(db);
      final clock = FixedClock(DateTime(2026, 10));
      final record = RecordNetWorth(
        assets: DriftAssetRepository(db),
        investments: DriftInvestmentRepository(db),
        debts: DriftDebtRepository(db),
        history: history,
        clock: clock,
        ids: SequentialIds(),
      );
      await DriftDebtRepository(db).save(
        const Debt(
          id: 'car-loan',
          name: 'Crédito carro',
          type: DebtType.bankLoan,
          originalAmount: Money.pesos(40000000),
          currentBalance: Money.pesos(30000000),
        ),
      );
      await DriftAssetRepository(db).save(
        Asset(
          id: 'car',
          name: 'Carro',
          type: AssetType.vehicle,
          currentValue: const Money.pesos(50000000),
          valuedAt: DateTime(2026, 10),
          linkedDebtId: 'car-loan',
        ),
      );

      await record();
      clock.value = DateTime(2026, 10, 20);
      await record();
      clock.value = DateTime(2026, 11, 2);
      await record();

      final all = await history.watchAll().first;
      expect(all, hasLength(2), reason: 'octubre se reemplazó');
      expect(all.first.total, const Money.pesos(20000000));

      await DriftDebtRepository(db).delete('car-loan');
      final car = (await DriftAssetRepository(db).getAll()).single;
      expect(car.linkedDebtId, isNull, reason: 'el vínculo se limpia');
    },
  );

  test('aplicar el reparto aporta a la meta y abona a la deuda', () async {
    final db = createTestDatabase();
    final goals = DriftSavingsGoalRepository(db);
    final debts = DriftDebtRepository(db);
    final transactions = DriftTransactionRepository(db);
    await goals.save(
      const SavingsGoal(
        id: 'fondo',
        name: 'Fondo',
        type: GoalType.emergency,
        targetAmount: Money.pesos(5000000),
      ),
    );
    await debts.save(
      const Debt(
        id: 'card',
        name: 'Tarjeta',
        type: DebtType.creditCard,
        originalAmount: Money.pesos(2000000),
        currentBalance: Money.pesos(1000000),
      ),
    );
    final apply = ApplyWindfallSlices(
      goals: goals,
      debts: debts,
      transactions: transactions,
      clock: FixedClock(DateTime(2026, 10, 3)),
      ids: SequentialIds(),
    );

    final result = await apply(const [
      WindfallSlice(
        use: WindfallUse.emergencyFund,
        amount: Money.pesos(600000),
        reason: '',
        label: 'Fondo',
        targetId: 'fondo',
      ),
      WindfallSlice(
        use: WindfallUse.debt,
        amount: Money.pesos(300000),
        reason: '',
        label: 'Tarjeta',
        targetId: 'card',
      ),
      WindfallSlice(
        use: WindfallUse.investment,
        amount: Money.pesos(100000),
        reason: '',
      ),
    ]);

    expect(result.isOk, isTrue);
    expect(
      (await goals.getContributions()).single.amount,
      const Money.pesos(600000),
    );
    expect(
      (await debts.getById('card'))!.currentBalance,
      const Money.pesos(700000),
    );
    final saved = await transactions.getRecent(limit: 10);
    expect(saved, hasLength(2), reason: 'la inversión es solo guía');
    expect(
      saved.map((t) => t.categoryId),
      containsAll([DefaultCategories.investmentsId, DefaultCategories.debtsId]),
    );
  });
}
