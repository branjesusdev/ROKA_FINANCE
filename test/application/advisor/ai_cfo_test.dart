import 'dart:convert';

import 'package:finance_app/application/advisor/ai_cfo.dart';
import 'package:finance_app/application/advisor/ai_ports.dart';
import 'package:finance_app/application/advisor/financial_snapshot.dart';
import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/money_overview.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/advisor/ai_review.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/net_worth_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  final now = DateTime(2026, 10, 12, 9);
  const reviewJson = '''
Claro, aquí va:
```json
{
  "headline": "Vas bien, pero la tarjeta te está costando caro.",
  "recommendations": [
    {"title": "Ahorra el 10%", "priority": "low", "action": "Aparta hoy"},
    {"title": "Abona a la tarjeta", "priority": "high", "why": "30% EA",
     "dataUsed": "saldo 2.000.000", "benefit": "menos intereses",
     "risks": "menos liquidez", "assumptions": "tasa fija",
     "action": "Abona 300.000"}
  ],
  "missingData": ["Tasa del crédito de vivienda"]
}
```''';

  FinancialSnapshot snapshot() {
    final today = DateTime(2026, 10, 3);
    final cycle = PayCycle.containing(today, payday: 20);
    final transactions = [
      Transaction(
        id: 't1',
        kind: TransactionKind.expense,
        amount: const Money.pesos(45000),
        categoryId: 'seed-expense-food',
        date: today,
        createdAt: today,
        description: 'Cena con Laura en Andrés',
        notes: 'secreto',
      ),
    ];
    final summary = const CycleSummaryBuilder().build(
      cycle: cycle,
      today: today,
      cycleTransactions: transactions,
      previousCycleTransactions: const [],
      categories: DefaultCategories.all,
      fixedMovements: const [],
      settings: const FinanceSettings(),
    );
    return const FinancialSnapshotBuilder().build(
      summary: summary,
      overview: const MoneyOverviewBuilder().build(
        summary: summary,
        categories: DefaultCategories.all,
        fixedMovements: const [],
        cycleTransactions: transactions,
      ),
      alerts: const [],
      categories: DefaultCategories.all,
      cycleTransactions: transactions,
      previousCycleTransactions: const [],
      debts: const [
        Debt(
          id: 'd1',
          name: 'Préstamo de mi mamá',
          type: DebtType.personalLoan,
          originalAmount: Money.pesos(1000000),
          currentBalance: Money.pesos(500000),
        ),
      ],
      assets: const [],
      investments: const [],
      goals: const [],
      netWorth: const NetWorthCalculator().calculate(
        assets: const [],
        investments: const [],
        debts: const [],
      ),
      settings: const FinanceSettings(),
    );
  }

  group('resumen para la IA', () {
    test('no incluye descripciones, notas ni nombres escritos', () {
      final json = snapshot().toJson();

      expect(json, isNot(contains('Laura')));
      expect(json, isNot(contains('secreto')));
      expect(json, isNot(contains('mamá')));
      expect(json, contains('Deuda 1 (personalLoan)'));
      expect(json, contains('Alimentación'), reason: 'nombre de categoría');
      final data = jsonDecode(json) as Map<String, Object?>;
      expect(
        (data['gastoPorCategoriaEsteCiclo']! as Map)['Alimentación'],
        45000,
        reason: 'pesos enteros',
      );
    });
  });

  group('lectura de la respuesta', () {
    test('tolera texto y bloques de código alrededor del JSON', () {
      final review = AiReviewParser.parse(reviewJson, id: 'r1', createdAt: now);

      expect(review.headline, startsWith('Vas bien'));
      expect(review.recommendations, hasLength(2));
      expect(review.top?.title, 'Abona a la tarjeta');
      expect(review.top?.risks, 'menos liquidez');
      expect(review.missingData, ['Tasa del crédito de vivienda']);
    });

    test('sin JSON es una respuesta inválida', () {
      expect(
        () => AiReviewParser.parse('Hola', id: 'r', createdAt: now),
        throwsA(isA<AiAdvisorException>()),
      );
    });
  });

  group('revisión con IA', () {
    late FakeAiAdvisor advisor;
    late FakeAiKeyStore keys;
    late FakeAiReviewRepository reviews;
    late FakeSettingsRepository settings;
    late RunAiReview run;

    setUp(() {
      advisor = FakeAiAdvisor()..response = reviewJson;
      keys = FakeAiKeyStore('gsk_test');
      reviews = FakeAiReviewRepository();
      settings = FakeSettingsRepository(const FinanceSettings(aiEnabled: true));
      run = RunAiReview(
        advisor: advisor,
        keys: keys,
        reviews: reviews,
        settings: settings,
        clock: FixedClock(now),
        ids: SequentialIds(),
      );
    });

    test('envía solo el resumen y guarda la revisión', () async {
      final result = await run(snapshot());

      expect(result, isA<Ok<AiReview>>());
      expect(reviews.saved.single.createdAt, now);
      expect(advisor.prompts.single, snapshot().toJson());
    });

    test('sin consentimiento no envía nada', () async {
      settings.value = const FinanceSettings();

      final result = await run(snapshot());

      expect(
        result,
        isA<Err<AiReview>>().having(
          (e) => (e.failure as RemoteFailure).message,
          'code',
          aiDisabledCode,
        ),
      );
      expect(advisor.prompts, isEmpty);
    });

    test('sin llave o con llave revocada: falla explicada', () async {
      keys.key = null;
      final missing = await run(snapshot());
      expect((missing as Err).failure.message, 'missingKey');

      keys.key = 'gsk_vieja';
      advisor.error = const AiAdvisorException(AiFailureReason.unauthorized);
      final revoked = await run(snapshot());
      expect((revoked as Err).failure.message, 'unauthorized');
      expect(reviews.saved, isEmpty);
    });

    test('la revisión periódica toca según la frecuencia', () async {
      expect(await run.isDue(), isTrue, reason: 'nunca se ha revisado');
      await run(snapshot());
      expect(await run.isDue(), isFalse, reason: 'semanal, recién hecha');

      settings.value = const FinanceSettings();
      expect(await run.isDue(), isFalse, reason: 'apagada');
    });

    test('preguntar usa el resumen como contexto', () async {
      advisor.response = 'Abona primero a la tarjeta. Qué haría hoy: …';
      final ask = AskCfo(advisor: advisor, keys: keys, settings: settings);

      final result = await ask(
        snapshot: snapshot(),
        question: '¿Abono o ahorro?',
      );

      expect((result as Ok<String>).value, startsWith('Abona'));
      expect(advisor.prompts.single, contains('¿Abono o ahorro?'));
    });
  });

  test('frecuencias de revisión', () {
    final last = DateTime(2026, 10, 1, 8);
    expect(
      ReviewFrequency.daily.isDue(last: last, now: DateTime(2026, 10, 2, 8)),
      isTrue,
    );
    expect(
      ReviewFrequency.weekly.isDue(last: last, now: DateTime(2026, 10, 7)),
      isFalse,
    );
    expect(
      ReviewFrequency.monthly.isDue(last: null, now: DateTime(2026, 10, 7)),
      isTrue,
    );
  });
}
