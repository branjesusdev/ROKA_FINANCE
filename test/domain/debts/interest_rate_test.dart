import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NMV se divide entre 12', () {
    const rate = InterestRate(
      rate: Percentage.whole(12),
      type: InterestRateType.nominalAnnualMonthly,
    );
    expect(rate.monthlyEffective, closeTo(0.01, 1e-12));
  });

  test('EM se usa directamente', () {
    const rate = InterestRate(
      rate: Percentage.basisPoints(150),
      type: InterestRateType.effectiveMonthly,
    );
    expect(rate.monthlyEffective, closeTo(0.015, 1e-12));
  });

  test('EA se convierte con interés compuesto', () {
    const rate = InterestRate(
      rate: Percentage.basisPoints(1268),
      type: InterestRateType.effectiveAnnual,
    );
    expect(rate.monthlyEffective, closeTo(0.01, 1e-4));
  });

  test('EA → EM → EA es reversible', () {
    const rate = InterestRate(
      rate: Percentage.whole(18),
      type: InterestRateType.effectiveAnnual,
    );
    expect(rate.annualEffective, closeTo(0.18, 1e-9));
  });
}
