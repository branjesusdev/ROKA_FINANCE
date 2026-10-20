import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/salary_forecast.dart';
import 'package:finance_app/application/dashboard/spend_check.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  final today = DateTime(2026, 10, 3, 18);
  final cycle = PayCycle.containing(today, payday: 20);
  const rent = FixedMovement(
    id: 'rent',
    name: 'Arriendo',
    kind: TransactionKind.expense,
    amount: Money.pesos(1000000),
    categoryId: 'seed-expense-housing',
    dayOfMonth: 5,
  );
  const salarySettings = FinanceSettings(monthlySalary: Money.pesos(3400000));

  CycleSummary summary({List<FixedMovement> fixed = const [rent]}) =>
      const CycleSummaryBuilder().build(
        cycle: cycle,
        today: today,
        cycleTransactions: [
          income(
            3400000,
            category: DefaultCategories.salaryId,
            date: DateTime(2026, 9, 20),
          ),
        ],
        previousCycleTransactions: const [],
        categories: DefaultCategories.all,
        fixedMovements: fixed,
        settings: const FinanceSettings(),
      );

  SalaryForecast forecast({
    FinanceSettings settings = salarySettings,
    int? dayToDay = 1500000,
    List<FixedMovement> fixed = const [rent],
    List<Debt> debts = const [],
  }) => const SalaryForecastBuilder().build(
    summary: summary(fixed: fixed),
    settings: settings,
    fixedMovements: fixed,
    debts: debts,
    historyDayToDay: dayToDay == null ? null : Money.pesos(dayToDay),
  );

  group('SalaryForecastBuilder', () {
    test('acumula sueldo − fijos − gasto variable cada ciclo', () {
      final result = forecast();
      expect(result.source, SalarySource.configured);
      // 2.400.000 tras el arriendo − 17/30 de 1.500.000 a tu ritmo.
      expect(result.cycleEnd, const Money.pesos(1550000));
      expect(result.months, hasLength(SalaryForecastBuilder.horizon));
      expect(result.months.first.payday, DateTime(2026, 10, 20));
      expect(result.months[1].payday, DateTime(2026, 11, 20));
      expect(result.months.first.net, const Money.pesos(900000));
      expect(result.months.first.balance, const Money.pesos(2450000));
      expect(result.last, const Money.pesos(6950000));
      expect(result.staysPositive, isTrue);
    });

    test('si gastas más de lo que ganas, avisa el primer mes corto', () {
      final result = forecast(dayToDay: 2600000);
      expect(result.months.first.net, const Money.pesos(-200000));
      final short = result.firstShort!;
      expect(short.payday, DateTime(2027, 2, 20));
      expect(short.balance.isNegative, isTrue);
    });

    test('cuándo se puede pagar algo sin quedar en rojo', () {
      final result = forecast();
      expect(result.whenAffordable(const Money.pesos(1000000)).isNow, isTrue);
      // 3.000.000: este ciclo y el siguiente no alcanzan; desde noviembre sí.
      final later = result.whenAffordable(const Money.pesos(3000000));
      expect(later.date, DateTime(2026, 11, 20));
      final never = result.whenAffordable(const Money.pesos(50000000));
      expect(never.reachable, isFalse);
      expect(
        result.withSpend(const Money.pesos(3000000)).shortThisCycle,
        isTrue,
      );
    });

    test('sin sueldo en Ajustes usa el que llegó a Salario', () {
      final result = forecast(settings: const FinanceSettings());
      expect(result.source, SalarySource.thisCycle);
      expect(result.salary, const Money.pesos(3400000));
    });

    test('sin historial supone que gastas tu tope y ahorras tu meta', () {
      final result = forecast(dayToDay: null);
      expect(result.dayToDayFromHistory, isFalse);
      // 3.400.000 − 1.000.000 − 10% de ahorro.
      expect(result.dayToDayMonthly, const Money.pesos(2060000));
      expect(result.months.first.net, const Money.pesos(340000));
    });

    test('la cuota de un crédito deja de contar cuando se termina', () {
      const quota = FixedMovement(
        id: 'quota',
        name: 'Cuota carro',
        kind: TransactionKind.expense,
        amount: Money.pesos(500000),
        categoryId: 'seed-expense-debts',
        dayOfMonth: 10,
        debtId: 'car',
      );
      const car = Debt(
        id: 'car',
        name: 'Carro',
        type: DebtType.bankLoan,
        originalAmount: Money.pesos(5000000),
        currentBalance: Money.pesos(1000000),
        terms: LoanTerms(
          rate: InterestRate(
            rate: Percentage.whole(20),
            type: InterestRateType.effectiveAnnual,
          ),
          monthlyPayment: Money.pesos(500000),
          totalInstallments: 10,
          paidInstallments: 8,
        ),
      );
      final result = forecast(fixed: const [rent, quota], debts: const [car]);
      // Faltan 2 cuotas: la de este ciclo y una más.
      expect(result.months[0].fixedExpenses, const Money.pesos(1500000));
      expect(result.months[1].fixedExpenses, const Money.pesos(1000000));
    });
  });

  group('¿Puedo gastar…? con la proyección', () {
    SpendCheck check(int pesos, {SalaryForecast? using}) =>
        const SpendCheckBuilder().build(
          summary: summary(),
          amount: Money.pesos(pesos),
          forecast: using,
        )!;

    test('SÍ cuando cabe este ciclo y ningún mes queda en rojo', () {
      final result = check(600000, using: forecast());
      expect(result.verdict, SpendVerdict.fitsWithRecovery);
      expect(result.decision.canSpend, isTrue);
      expect(result.billsBeforePayday.single.movement, rent);
      expect(result.billsTotal, const Money.pesos(1000000));
    });

    test('NO si un mes siguiente cerraría en rojo, aunque hoy alcance', () {
      final tight = forecast(dayToDay: 2600000);
      expect(check(600000).decision.canSpend, isTrue);
      final result = check(600000, using: tight);
      expect(result.decision.canSpend, isFalse);
      expect(result.decision.reason, SpendNoReason.shortLater);
      expect(result.decision.shortMonth!.payday, DateTime(2026, 11, 20));
    });

    test('lo que cabe en el tope de hoy siempre es SÍ', () {
      final result = check(10000, using: forecast(dayToDay: 2600000));
      expect(result.verdict, SpendVerdict.fitsToday);
      expect(result.decision.canSpend, isTrue);
    });

    test('NO si toca la plata de los fijos, y dice cuándo sí', () {
      final result = check(3000000, using: forecast());
      expect(result.decision.reason, SpendNoReason.touchesFixed);
      expect(result.decision.when.date, DateTime(2026, 11, 20));
    });

    test('una compra grande frente al sueldo pide 24 horas', () {
      final result = check(700000, using: forecast());
      expect(result.decision.canSpend, isTrue);
      expect(result.decision.isBig, isTrue);
    });
  });
}
