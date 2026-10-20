import 'package:finance_app/application/debts/debt_overview.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Crédito de libre inversión real: 43.957.828 a 48 cuotas, 18,01% EA,
  // cuota 1.288.000 con 26.000 de seguros, desembolso 7 may 2024. Con
  // abonos de más, el saldo a capital tras la cuota 29 es 19.415.057,80 y
  // la proyección del banco termina en la cuota 47 (abril 2028).
  Debt loan({int? paid = 29}) => Debt(
    id: 'libre',
    name: 'Libre inversión',
    type: DebtType.bankLoan,
    originalAmount: const Money(4395782800),
    currentBalance: const Money(1941505780),
    terms: LoanTerms(
      rate: const InterestRate(
        rate: Percentage.basisPoints(1801),
        type: InterestRateType.effectiveAnnual,
      ),
      monthlyPayment: const Money.pesos(1288000),
      monthlyFees: const Money.pesos(26000),
      totalInstallments: 48,
      paidInstallments: paid,
      startDate: DateTime(2024, 5, 7),
    ),
  );

  test('tabla de pagos como la proyección del banco', () {
    final overview = DebtOverview.build(
      debt: loan(),
      currentMonth: const YearMonth(2026, 10),
    );
    final rows = overview.schedule;
    expect(rows, hasLength(18));
    expect(rows.first.number, 30);
    expect(rows.first.month, const YearMonth(2026, 11));
    // Cuota 31 del banco: interés 255.996,24 y saldo 17.416.837,13.
    final second = rows[1];
    expect(second.number, 31);
    expect(second.interest.cents, closeTo(25599624, 200));
    expect(second.balance.cents, closeTo(1741683713, 2000));
    // Última: 47 en abril 2028 por 542.880,49.
    expect(rows.last.number, 47);
    expect(rows.last.month, const YearMonth(2028, 4));
    expect(rows.last.payment.cents, closeTo(54288049, 2000));
    expect(rows.last.balance, Money.zero);
  });

  test('suma los intereses del crédito completo y lo que ahorras', () {
    final overview = DebtOverview.build(
      debt: loan(),
      currentMonth: const YearMonth(2026, 10),
    );
    final cost = overview.interestCost!;
    // Lo que falta: 17 × 1.262.000 + 542.880,49 − 19.415.057,80.
    expect(cost.remaining.cents, closeTo(258182269, 5000));
    expect(cost.plan.cents, greaterThan(cost.total.cents));
    expect(cost.total, cost.paidSoFar + cost.remaining);
    expect(cost.savedVsPlan.isPositive, isTrue);
    // Registro: 48 − 29 = 19; por saldo: 18 ⇒ vas 1 cuota adelantado.
    expect(overview.installmentsAhead, 1);
  });

  test('sin cuotas pagadas no estima intereses ya pagados', () {
    final overview = DebtOverview.build(
      debt: loan(paid: null),
      currentMonth: const YearMonth(2026, 10),
    );
    expect(overview.interestCost, isNull);
    expect(overview.schedule.first.number, isNull);
    expect(overview.schedule.first.month, const YearMonth(2026, 11));
  });
}
