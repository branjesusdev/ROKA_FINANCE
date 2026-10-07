import 'package:finance_app/application/advisor/cfo_brief.dart';
import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/markets/load_watchlist.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/markets/watchlist.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  final today = DateTime(2026, 10, 3, 10);
  final cycle = PayCycle.containing(today, payday: 20);
  const food = 'seed-expense-food';

  CycleSummary summary({List<Transaction> current = const []}) =>
      const CycleSummaryBuilder().build(
        cycle: cycle,
        today: today,
        cycleTransactions: [
          income(
            4000000,
            category: DefaultCategories.salaryId,
            date: cycle.start,
          ),
          ...current,
        ],
        // Ciclo anterior: sobraron 1.000.000.
        previousCycleTransactions: [
          income(4000000, date: DateTime(2026, 8, 20)),
          expense(3000000, category: food, date: DateTime(2026, 8, 25)),
        ],
        categories: DefaultCategories.all,
        fixedMovements: const [],
        settings: const FinanceSettings(),
      );

  CfoBrief build({
    List<Transaction> current = const [],
    List<Debt> debts = const [],
    List<WatchQuote> watchlist = const [],
    bool alreadySaved = false,
  }) => const CfoBriefBuilder().build(
    cycle: summary(current: current),
    cycleTransactions: current,
    categories: DefaultCategories.all,
    debts: debts,
    goals: const [],
    essentialMonthly: const Money.pesos(2000000),
    settings: const FinanceSettings(),
    today: today,
    watchlist: watchlist,
    previousLeftAlreadySaved: alreadySaved,
  );

  test('lo que sobró del ciclo pasado: primero fondo de emergencia, luego '
      'inversión amplia y temática', () {
    final plan = build().plan!;

    expect(plan.fromPreviousCycle, isTrue);
    expect(plan.amount, const Money.pesos(1000000));
    expect(plan.slices.map((s) => s.kind), [
      PlanSliceKind.emergencyFund,
      PlanSliceKind.broadFund,
      PlanSliceKind.thematic,
    ]);
    expect(plan.slices.first.amount, const Money.pesos(500000));
    expect(plan.slices[1].amount, const Money.pesos(350000));
    expect(plan.idleCostPerYear, const Money.pesos(50000));
  });

  test('una deuda cara recibe parte del sobrante y genera alerta', () {
    final brief = build(
      debts: [
        const Debt(
          id: 'card',
          name: 'Tarjeta',
          type: DebtType.creditCard,
          originalAmount: Money.pesos(3000000),
          currentBalance: Money.pesos(2000000),
          terms: LoanTerms(
            rate: InterestRate(
              rate: Percentage.whole(28),
              type: InterestRateType.effectiveAnnual,
            ),
            monthlyPayment: Money.pesos(200000),
          ),
        ),
      ],
    );

    expect(brief.tips.whereType<ExpensiveDebtTip>(), hasLength(1));
    final debtSlice = brief.plan!.slices.singleWhere(
      (s) => s.kind == PlanSliceKind.debt,
    );
    expect(debtSlice.amount, const Money.pesos(250000));
    expect(debtSlice.label, 'Tarjeta');
  });

  test('si ya se guardó el sobrante, el plan es el ahorro del ciclo', () {
    final brief = build(alreadySaved: true);

    expect(brief.tips.whereType<IdleMoneyTip>(), isEmpty);
    expect(brief.plan!.fromPreviousCycle, isFalse);
    expect(brief.plan!.amount, const Money.pesos(400000), reason: '10%');
  });

  test('detecta fugas de compras pequeñas y su costo anual', () {
    final brief = build(
      current: [
        for (var i = 0; i < 4; i++)
          expense(10000, category: food, date: DateTime(2026, 9, 21 + i)),
      ],
    );

    final leaks = brief.tips.whereType<SmallLeaksTip>().single;
    expect(leaks.count, 4);
    expect(leaks.total, const Money.pesos(40000));
    // 14 días transcurridos del ciclo → 40.000 × 365 / 14.
    expect(leaks.yearlyPace, const Money.pesos(40000).times(365 / 14));
  });

  test('sugiere el temático más lejos de su máximo que aún sube', () {
    WatchQuote watch(String symbol, List<int> closes) {
      final quote = MarketQuote(
        symbol: symbol,
        currency: 'USD',
        lastPriceMinor: closes.last,
        weeklyClosesMinor: closes,
        asOf: today,
      );
      return WatchQuote(
        item: WatchItem(
          symbol: symbol,
          name: symbol,
          why: '',
          kind: WatchKind.company,
        ),
        quote: quote,
        stats: const MarketStatsCalculator().compute(quote),
      );
    }

    final plan = build(
      watchlist: [
        watch('NEAR', [100, 150, 145]),
        watch('DIP', [100, 200, 130]),
        watch('DOWN', [200, 100, 50]),
      ],
    ).plan!;

    expect(plan.thematicPick?.item.symbol, 'DIP');
  });
}
