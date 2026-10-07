import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MarketQuote quote(List<int> closes, {int? last}) => MarketQuote(
    symbol: 'TEST',
    currency: 'USD',
    lastPriceMinor: last ?? closes.last,
    weeklyClosesMinor: closes,
    asOf: DateTime(2026, 10, 6),
  );

  test('variación del año, del trimestre y distancia al máximo', () {
    // 20 semanas: sube de 100 a 200 y cierra en 150.
    final closes = [for (var i = 0; i < 20; i++) 10000 + i * 500, 15000];
    final stats = const MarketStatsCalculator().compute(quote(closes));

    expect(stats.change1y, const Percentage.whole(50));
    expect(stats.fromHigh, Percentage.fromFraction(15000 / 19500 - 1));
    expect(stats.change3m, isNotNull);
  });

  test('un precio estable es poco volátil; uno que salta, muy volátil', () {
    const calculator = MarketStatsCalculator();
    final calm = calculator.compute(
      quote([for (var i = 0; i < 52; i++) 10000 + (i.isEven ? 10 : -10)]),
    );
    final wild = calculator.compute(
      quote([
        for (var i = 0; i < 52; i++)
          if (i.isEven) 10000 else 14000,
      ]),
    );

    expect(calm.level, VolatilityLevel.low);
    expect(wild.level, VolatilityLevel.high);
  });

  test('sin datos no inventa cifras', () {
    final stats = const MarketStatsCalculator().compute(quote([], last: 0));

    expect(stats.change1y, isNull);
    expect(stats.level, isNull);
  });
}
