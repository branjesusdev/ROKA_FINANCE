import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/wealth/asset.dart';

final class NetWorth {
  const new({
    required this.assets,
    required this.investments,
    required this.liabilities,
  });

  final Money assets;
  final Money investments;
  final Money liabilities;

  Money get totalAssets => assets + investments;

  /// Patrimonio neto = activos (incl. inversiones) − pasivos.
  Money get total => totalAssets - liabilities;

  /// Pasivos sobre activos. `null` si no hay activos.
  Percentage? get debtRatio => Percentage.ratio(liabilities, totalAssets);
}

final class NetWorthCalculator {
  const new();

  NetWorth calculate({
    required List<Asset> assets,
    required List<Investment> investments,
    required List<Debt> debts,
  }) => NetWorth(
    assets: Money.sum(assets.map((a) => a.currentValue)),
    investments: Money.sum(investments.map((i) => i.currentValue)),
    liabilities: Money.sum(debts.map((d) => d.currentBalance.max(Money.zero))),
  );
}
