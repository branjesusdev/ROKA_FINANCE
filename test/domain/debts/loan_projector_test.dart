import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_projector.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const projector = LoanProjector();
  const november = YearMonth(2026, 11);

  LoanTerms monthly(int basisPoints, {required int payment, int fees = 0}) =>
      LoanTerms(
        rate: InterestRate(
          rate: Percentage.basisPoints(basisPoints),
          type: InterestRateType.effectiveMonthly,
        ),
        monthlyPayment: Money.pesos(payment),
        monthlyFees: Money.pesos(fees),
      );

  test('calcula intereses mes a mes sobre el saldo', () {
    // 100.000 al 1% EM con cuota de 50.000:
    // M1 interés 1.000 → saldo 51.000; M2 interés 510 → saldo 1.510;
    // M3 interés 15,10 → saldo 0.
    final projection = projector.project(
      balance: const Money.pesos(100000),
      terms: monthly(100, payment: 50000),
      firstPaymentMonth: november,
    );
    expect(projection.isPayable, isTrue);
    expect(projection.months, 3);
    expect(projection.totalInterest, const Money(152510));
    expect(projection.payoffMonth, const YearMonth(2027, 1));
  });

  test('los seguros/comisiones no abonan a capital', () {
    final projection = projector.project(
      balance: const Money.pesos(1000000),
      terms: monthly(0, payment: 300000, fees: 50000),
      firstPaymentMonth: november,
    );
    expect(projection.months, 4);
    expect(projection.totalInterest, Money.zero);
    expect(projection.totalFees, const Money.pesos(200000));
  });

  group('crédito de 20.000.000 al 18% EA con cuota de 1.300.000', () {
    const terms = LoanTerms(
      rate: InterestRate(
        rate: Percentage.whole(18),
        type: InterestRateType.effectiveAnnual,
      ),
      monthlyPayment: Money.pesos(1300000),
    );
    const balance = Money.pesos(20000000);

    test('proyecta cuotas restantes, fecha e intereses', () {
      final projection = projector.project(
        balance: balance,
        terms: terms,
        firstPaymentMonth: november,
      );
      expect(projection.months, 18);
      expect(projection.payoffMonth, const YearMonth(2028, 4));
      expect(
        projection.totalInterest.cents,
        inInclusiveRange(
          const Money.pesos(2500000).cents,
          const Money.pesos(2800000).cents,
        ),
      );
    });

    test('simula 200.000 adicionales al mes', () {
      final comparison = projector.compareExtraPayment(
        balance: balance,
        terms: terms,
        firstPaymentMonth: november,
        extraMonthly: const Money.pesos(200000),
      );
      expect(comparison.withExtra.months, 15);
      expect(comparison.monthsSaved, 3);
      expect(comparison.interestSaved!.isPositive, isTrue);
    });
  });

  test('cuota que no cubre intereses: la deuda no termina', () {
    final comparison = projector.compareExtraPayment(
      balance: const Money.pesos(10000000),
      terms: monthly(300, payment: 200000),
      firstPaymentMonth: november,
      extraMonthly: const Money.pesos(50000),
    );
    expect(comparison.base.isPayable, isFalse);
    expect(comparison.base.payoffMonth, isNull);
    expect(comparison.monthsSaved, isNull);
  });

  group('principalPortion', () {
    final terms = monthly(100, payment: 50000, fees: 10000);

    test('descuenta cargos e interés del mes', () {
      expect(
        projector.principalPortion(
          balance: const Money.pesos(100000),
          terms: terms,
          payment: const Money.pesos(50000),
        ),
        const Money.pesos(39000),
      );
    });

    test('nunca es negativa ni mayor que el saldo', () {
      expect(
        projector.principalPortion(
          balance: const Money.pesos(100000),
          terms: terms,
          payment: const Money.pesos(5000),
        ),
        Money.zero,
      );
      expect(
        projector.principalPortion(
          balance: const Money.pesos(1000),
          terms: terms,
          payment: const Money.pesos(50000),
        ),
        const Money.pesos(1000),
      );
    });
  });
}
