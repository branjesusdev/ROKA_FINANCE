import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';

final class PortfolioSummary {
  const new({required this.invested, required this.current});

  final Money invested;
  final Money current;

  Money get gain => current - invested;
  Percentage? get returnRate => Percentage.ratio(gain, invested);
}

final class PortfolioCalculator {
  const new();

  PortfolioSummary summarize(List<Investment> investments) => PortfolioSummary(
    invested: Money.sum(investments.map((i) => i.investedAmount)),
    current: Money.sum(investments.map((i) => i.currentValue)),
  );
}
