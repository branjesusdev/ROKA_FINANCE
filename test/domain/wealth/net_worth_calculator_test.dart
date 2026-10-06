import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/domain/wealth/net_worth_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime(2026, 10);

  Asset asset(int pesos) => Asset(
    id: 'a$pesos',
    name: 'Activo',
    type: AssetType.bankAccount,
    currentValue: Money.pesos(pesos),
    valuedAt: date,
  );

  Debt debt(int balance) => Debt(
    id: 'd$balance',
    name: 'Crédito',
    type: DebtType.bankLoan,
    originalAmount: const Money.pesos(5000000),
    currentBalance: Money.pesos(balance),
  );

  final netWorth = const NetWorthCalculator().calculate(
    assets: [asset(10000000), asset(5000000)],
    investments: [
      Investment(
        id: 'i1',
        name: 'Fondo',
        type: InvestmentType.fund,
        investedAmount: const Money.pesos(2000000),
        currentValue: const Money.pesos(3000000),
        date: date,
      ),
    ],
    debts: [debt(4000000), debt(-100)],
  );

  test('patrimonio = activos + inversiones − pasivos', () {
    expect(netWorth.totalAssets, const Money.pesos(18000000));
    expect(netWorth.liabilities, const Money.pesos(4000000));
    expect(netWorth.total, const Money.pesos(14000000));
  });

  test('saldos negativos de deuda no restan pasivos', () {
    expect(netWorth.liabilities, const Money.pesos(4000000));
  });

  test('porcentaje de deuda sobre activos', () {
    expect(netWorth.debtRatio, const Percentage.basisPoints(2222));
  });
}
