import 'dart:math' as math;

import 'package:finance_app/application/markets/load_usd_rate.dart';
import 'package:finance_app/application/markets/value_investments.dart';
import 'package:finance_app/application/wealth/wealth_use_cases.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/markets/quarter_outlook.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/usd_rate.dart';
import 'package:finance_app/infrastructure/repositories/drift_investment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_database.dart';

void main() {
  final now = DateTime(2026, 10, 12, 9);

  /// 53 cierres semanales que crecen [weekly] por semana, con un vaivén
  /// de ±[swing] para que haya volatilidad.
  MarketQuote quote(
    String symbol, {
    required int start,
    double weekly = 0,
    double swing = 0,
    String currency = 'USD',
  }) {
    final closes = [
      for (var i = 0; i <= 52; i++)
        (start * math.pow(1 + weekly, i) * (1 + (i.isEven ? swing : -swing)))
            .round(),
    ];
    return MarketQuote(
      symbol: symbol,
      currency: currency,
      lastPriceMinor: closes.last,
      weeklyClosesMinor: closes,
      asOf: now,
    );
  }

  Investment stock(String id, String symbol, double units) => Investment(
    id: id,
    name: id,
    type: InvestmentType.stocks,
    investedAmount: const Money.pesos(1000000),
    currentValue: const Money.pesos(1000000),
    date: DateTime(2026),
    symbol: symbol,
    unitsMicros: (units * Investment.microsPerUnit).round(),
  );

  group('lectura a 3 meses', () {
    test('tendencia al alza con poco movimiento', () {
      final outlook = const QuarterOutlookCalculator().compute(
        quote('VOO', start: 10000, weekly: 0.004, swing: 0.005),
      )!;
      expect(outlook.trend, TrendDirection.up);
      expect(outlook.level, VolatilityLevel.low);
      expect(outlook.low, lessThan(outlook.typical));
      expect(outlook.high, greaterThan(outlook.typical));
      expect(outlook.worstQuarter, lessThanOrEqualTo(outlook.bestQuarter));
    });

    test('mucho vaivén: muy volátil y rango amplio', () {
      final outlook = const QuarterOutlookCalculator().compute(
        quote('HUMN', start: 10000, swing: 0.08),
      )!;
      expect(outlook.level, VolatilityLevel.high);
      expect(outlook.trend, TrendDirection.flat);
      expect(
        outlook.high.basisPoints - outlook.low.basisPoints,
        greaterThan(const Percentage.whole(30).basisPoints),
      );
    });

    test('sin 6 meses de historia no se estima', () {
      final short = MarketQuote(
        symbol: 'NEW',
        currency: 'USD',
        lastPriceMinor: 1000,
        weeklyClosesMinor: const [900, 950, 1000],
        asOf: now,
      );
      expect(const QuarterOutlookCalculator().compute(short), isNull);
    });
  });

  group('patrimonio con el precio real', () {
    late DriftInvestmentRepository repo;
    late FakeMarketDataSource market;
    late RefreshInvestmentPrices refresh;

    setUp(() {
      repo = DriftInvestmentRepository(createTestDatabase());
      market = FakeMarketDataSource();
      refresh = RefreshInvestmentPrices(
        investments: repo,
        market: market,
        clock: FixedClock(now),
      );
    });

    test('valora en pesos con la tasa de cambio y guarda el valor', () async {
      // 2,5 acciones a 120 USD con el dólar a 4.000 = 1.200.000 pesos.
      await repo.save(stock('nvda', 'NVDA', 2.5));
      market.quotes['NVDA'] = quote('NVDA', start: 12000);
      market.quotes['COP=X'] = quote('COP=X', start: 400000, currency: 'COP');

      final views = (await refresh() as Ok<List<InvestmentMarketView>>).value;

      final saved = (await repo.getAll()).single;
      expect(saved.currentValue, const Money.pesos(1200000));
      expect(saved.priceUpdatedAt, now);
      expect(saved.gain, const Money.pesos(200000), reason: 'ganancia real');
      expect(views.single.outlook, isNotNull);
      expect(views.single.share, Percentage.hundred);
      expect(views.single.signals, contains(InvestmentSignal.concentrated));
      expect(market.requested, containsAll(['NVDA', 'COP=X']));
    });

    test(
      'un símbolo sin datos no tumba los demás ni cambia su valor',
      () async {
        await repo.save(stock('nvda', 'NVDA', 1));
        await repo.save(stock('eco', 'ECOPETROL.CL', 100));
        market.quotes['ECOPETROL.CL'] = quote(
          'ECOPETROL.CL',
          start: 250000,
          currency: 'COP',
        );

        final views = (await refresh() as Ok<List<InvestmentMarketView>>).value;

        final byId = {for (final v in views) v.investment.id: v};
        expect(byId['nvda']!.failed, isTrue);
        expect(byId['eco']!.failed, isFalse);
        final stored = {for (final i in await repo.getAll()) i.id: i};
        expect(stored['nvda']!.currentValue, const Money.pesos(1000000));
        expect(stored['nvda']!.priceUpdatedAt, isNull);
        // 100 acciones × 2.500 pesos, sin conversión.
        expect(stored['eco']!.currentValue, const Money.pesos(250000));
        expect(market.requested, isNot(contains('COP=X')));
      },
    );

    test('sin símbolo no consulta internet', () async {
      await repo.save(
        Investment(
          id: 'cdt',
          name: 'CDT',
          type: InvestmentType.fixedTerm,
          investedAmount: const Money.pesos(1000000),
          currentValue: const Money.pesos(1050000),
          date: DateTime(2026),
        ),
      );
      final views = (await refresh() as Ok<List<InvestmentMarketView>>).value;
      expect(views, isEmpty);
      expect(market.requested, isEmpty);
    });
  });

  group('guardar una acción', () {
    Future<Result<Investment>> call(String? symbol, int? units) =>
        SaveInvestment(
          investments: DriftInvestmentRepository(createTestDatabase()),
          clock: FixedClock(now),
          ids: SequentialIds(),
        )(
          name: 'Acción',
          type: InvestmentType.stocks,
          invested: const Money.pesos(100000),
          currentValue: const Money.pesos(100000),
          symbol: symbol,
          unitsMicros: units,
        );
    test('el símbolo queda en mayúsculas', () async {
      final result = await call(' nvda ', 1000000);
      expect((result as Ok<Investment>).value.symbol, 'NVDA');
    });

    test('símbolo inválido o sin cantidad: error explicado', () async {
      final invalid = await call('NV DA', 1000000);
      expect((invalid as Err).failure, isA<ValidationFailure>());
      final noUnits = await call('NVDA', null);
      expect((noUnits as Err).failure.message, 'units_required');
    });
  });

  group('inversión pagada en dólares', () {
    test('253,70 dólares se guardan en pesos con el dólar escrito', () async {
      final repo = DriftInvestmentRepository(createTestDatabase());
      final result =
          await SaveInvestment(
            investments: repo,
            clock: FixedClock(now),
            ids: SequentialIds(),
          )(
            name: 'Nvidia',
            type: InvestmentType.stocks,
            invested: Money.zero,
            currentValue: Money.zero,
            investedUsdCents: 25370,
            usdRate: const UsdRate(Money.pesos(4000)),
          );
      final saved = (result as Ok<Investment>).value;
      expect(saved.investedUsdCents, 25370);
      expect(saved.investedAmount, const Money.pesos(1014800));
      expect((await repo.getAll()).single.investedUsdCents, 25370);
    });

    test('sin precio del dólar no se puede convertir', () async {
      final result =
          await SaveInvestment(
            investments: DriftInvestmentRepository(createTestDatabase()),
            clock: FixedClock(now),
            ids: SequentialIds(),
          )(
            name: 'X',
            type: InvestmentType.stocks,
            invested: Money.zero,
            currentValue: Money.zero,
            investedUsdCents: 25370,
          );
      expect((result as Err).failure.message, 'usd_rate_required');
    });

    test('el dólar de hoy sale de COP=X', () async {
      final market = FakeMarketDataSource();
      market.quotes['COP=X'] = quote('COP=X', start: 410050, currency: 'COP');
      final rate = await LoadUsdRate(market)();
      expect(rate!.pesosPerDollar, const Money(410050));
      expect(await LoadUsdRate(FakeMarketDataSource())(), isNull);
    });

    test('rentabilidad en dólares, sin el efecto del dólar', () {
      final view = InvestmentMarketView(
        investment: Investment(
          id: 'n',
          name: 'n',
          type: InvestmentType.stocks,
          investedAmount: const Money.pesos(1000000),
          currentValue: const Money.pesos(1200000),
          date: DateTime(2026),
          symbol: 'NVDA',
          unitsMicros: 2 * Investment.microsPerUnit,
          investedUsdCents: 20000,
        ),
        quote: quote('NVDA', start: 12000),
      );
      expect(view.quoteValueMinor, 24000);
      expect(view.usdReturn, const Percentage.whole(20));
    });
  });
}
