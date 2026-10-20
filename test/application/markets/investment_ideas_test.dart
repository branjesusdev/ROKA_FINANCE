import 'package:finance_app/application/markets/investment_ideas_question.dart';
import 'package:finance_app/application/markets/load_watchlist.dart';
import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/markets/watch_score.dart';
import 'package:finance_app/domain/markets/watchlist.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  QuoteStats stats({
    required int year,
    required int volatility,
    int quarter = 0,
    int fromHigh = -5,
  }) => QuoteStats(
    change3m: Percentage.whole(quarter),
    change1y: Percentage.whole(year),
    fromHigh: Percentage.whole(fromHigh),
    volatility: Percentage.whole(volatility),
    level: volatility >= 45
        ? VolatilityLevel.high
        : volatility >= 25
        ? VolatilityLevel.medium
        : VolatilityLevel.low,
  );

  WatchQuote quote(String symbol, WatchKind kind, QuoteStats? s) => WatchQuote(
    item: WatchItem(symbol: symbol, name: symbol, why: '', kind: kind),
    stats: s,
    score: const WatchScoreCalculator().score(kind, s),
  );

  test('ordena por balance: sube con poca volatilidad y reparte el riesgo '
      'primero; sin datos al final', () {
    final ranked = LoadWatchlist.rank([
      quote('NODATA', WatchKind.company, null),
      quote('WILD', WatchKind.company, stats(year: 30, volatility: 70)),
      quote('VT', WatchKind.broadFund, stats(year: 18, volatility: 14)),
      quote('BOTZ', WatchKind.thematicFund, stats(year: 25, volatility: 28)),
    ]);

    expect(ranked.map((q) => q.item.symbol), ['VT', 'BOTZ', 'WILD', 'NODATA']);
    expect(ranked.first.score!.risk, RiskType.conservative);
    expect(ranked[2].score!.risk, RiskType.veryAggressive);
    expect(ranked.last.score, isNull);
  });

  test('la pregunta lleva el monto y la lista ordenada, sin datos sin '
      'precio', () {
    final ranked = LoadWatchlist.rank([
      quote('VT', WatchKind.broadFund, stats(year: 18, volatility: 14)),
      quote('NODATA', WatchKind.company, null),
    ]);

    final question = InvestmentIdeasQuestion.build(
      ranked: ranked,
      amount: const DollarsAmount(20000),
    );

    expect(question, contains(r'US$ 200'));
    expect(question, contains('1. VT (fondo amplio, riesgo bajo)'));
    expect(question, contains('12m +18%'));
    expect(question, isNot(contains('NODATA')));
  });
}
