import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/investments/investment_repository.dart';
import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/markets/quarter_outlook.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';

/// Lo que conviene saber de una inversión según su precio real.
enum InvestmentSignal {
  /// Pesa mucho dentro de lo que tienes invertido.
  concentrated,

  /// Su precio se mueve mucho (puede caer fuerte en semanas).
  volatile,

  /// Está muy por debajo de su máximo del año.
  farFromHigh,

  /// Viene bajando en el último año.
  downTrend,

  /// Viene subiendo en el último año.
  upTrend,
}

/// Una inversión con precio de mercado y su lectura a 3 meses.
final class InvestmentMarketView {
  const new({
    required this.investment,
    this.quote,
    this.stats,
    this.outlook,
    this.share,
    this.failed = false,
  });

  /// Ya con el valor actualizado (si se pudo consultar).
  final Investment investment;
  final MarketQuote? quote;
  final QuoteStats? stats;
  final QuarterOutlook? outlook;

  /// Peso dentro de todas las inversiones.
  final Percentage? share;

  /// No se pudo consultar el precio (sin internet o símbolo inválido).
  final bool failed;

  Money get value => investment.currentValue;

  /// Valor de la posición en 3 meses si se mueve como el último año.
  Money? get lowIn3m =>
      outlook == null ? null : value.applyPercentage(outlook!.low) + value;
  Money? get highIn3m =>
      outlook == null ? null : value.applyPercentage(outlook!.high) + value;

  /// Valor de la posición en la moneda de la bolsa, en centésimas (US$).
  int? get quoteValueMinor => switch ((quote, investment.units)) {
    (final q?, final units?) => (q.lastPriceMinor * units).round(),
    _ => null,
  };

  /// Pesos por unidad de la moneda de la bolsa con que se valoró (el dólar
  /// de hoy si cotiza en US\$). `null` sin cotización.
  Money? get pesosPerQuoteUnit {
    final minor = quoteValueMinor;
    if (minor == null || minor <= 0) return null;
    return Money(value.cents * MarketQuote.minorPerUnit ~/ minor);
  }

  /// Rentabilidad en dólares, sin el efecto del precio del dólar. Solo si
  /// lo pagaste en dólares y cotiza en dólares.
  Percentage? get usdReturn {
    final invested = investment.investedUsdCents;
    final value = quoteValueMinor;
    if (invested == null || invested <= 0 || value == null) return null;
    if (quote!.currency.toUpperCase() != 'USD') return null;
    return Percentage.ratio(Money(value - invested), Money(invested));
  }

  /// Cuánto perderías si se repitiera su peor trimestre del año.
  Money? get worstQuarterLoss {
    final worst = outlook?.worstQuarter;
    if (worst == null || !worst.isNegative) return null;
    return value.applyPercentage(worst).abs;
  }

  List<InvestmentSignal> get signals => [
    if (share case final s? when s >= concentratedFrom)
      InvestmentSignal.concentrated,
    if (outlook?.level == VolatilityLevel.high) InvestmentSignal.volatile,
    if (stats?.fromHigh case final f? when f <= farFromHighAt)
      InvestmentSignal.farFromHigh,
    if (outlook?.trend == TrendDirection.down) InvestmentSignal.downTrend,
    if (outlook?.trend == TrendDirection.up) InvestmentSignal.upTrend,
  ];

  /// Desde aquí una sola inversión pesa demasiado.
  static const concentratedFrom = Percentage.whole(25);

  /// Desde aquí "lejos del máximo".
  static const farFromHighAt = Percentage.whole(-30);
}

/// Consulta el precio público de cada inversión con símbolo y cantidad,
/// actualiza su valor en pesos (patrimonio con rentabilidad real) y calcula
/// su lectura a 3 meses. Solo se envían los símbolos (y el de la tasa de
/// cambio), nunca montos ni nombres.
final class RefreshInvestmentPrices {
  const new({
    required this._investments,
    required this._market,
    required this._clock,
  });

  final InvestmentRepository _investments;
  final MarketDataSource _market;
  final Clock _clock;

  /// Símbolo de la tasa de cambio a pesos (`null` si ya está en COP).
  static String? fxSymbol(String currency) => switch (currency.toUpperCase()) {
    'COP' || '' => null,
    'USD' => 'COP=X',
    final other => '${other}COP=X',
  };

  Future<Result<List<InvestmentMarketView>>> call() => guardUseCase(() async {
    final all = await _investments.getAll();
    final rates = <String, Future<double?>>{};
    final now = _clock.now();
    final views = <InvestmentMarketView>[];
    final updated = {for (final i in all) i.id: i};
    for (final investment in all.where((i) => i.isMarketPriced)) {
      try {
        final quote = await _market.fetch(investment.symbol!);
        final rate = await rates.putIfAbsent(
          quote.currency,
          () => _copPerUnit(quote.currency),
        );
        if (rate == null) throw MarketDataException(investment.symbol!);
        // Precio en centésimas × unidades × pesos por unidad de moneda.
        final cents = quote.lastPriceMinor * investment.units! * rate;
        final priced = investment.copyWith(
          currentValue: Money(cents.round()),
          priceUpdatedAt: now,
        );
        await _investments.save(priced);
        updated[priced.id] = priced;
        views.add(
          InvestmentMarketView(
            investment: priced,
            quote: quote,
            stats: const MarketStatsCalculator().compute(quote),
            outlook: const QuarterOutlookCalculator().compute(quote),
          ),
        );
      } on MarketDataException {
        views.add(InvestmentMarketView(investment: investment, failed: true));
      }
    }
    final total = Money.sum(updated.values.map((i) => i.currentValue));
    return [
      for (final v in views)
        InvestmentMarketView(
          investment: v.investment,
          quote: v.quote,
          stats: v.stats,
          outlook: v.outlook,
          failed: v.failed,
          share: Percentage.ratio(v.investment.currentValue, total),
        ),
    ];
  });

  /// Pesos colombianos por unidad de [currency] (`null` si no se pudo).
  Future<double?> _copPerUnit(String currency) async {
    final symbol = fxSymbol(currency);
    if (symbol == null) return 1;
    try {
      final quote = await _market.fetch(symbol);
      if (quote.lastPriceMinor <= 0) return null;
      return quote.lastPriceMinor / Money.centsPerPeso;
    } on MarketDataException {
      return null;
    }
  }
}
