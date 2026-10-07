import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/markets/watchlist.dart';

/// Instrumento de la lista con su precio, si se pudo consultar.
final class WatchQuote {
  const new({required this.item, this.quote, this.stats});

  final WatchItem item;
  final MarketQuote? quote;
  final QuoteStats? stats;

  bool get hasData => quote != null;
}

/// Consulta los precios de la lista. Un símbolo que falla no tumba los
/// demás: queda sin datos.
final class LoadWatchlist {
  const new(this._source);

  final MarketDataSource _source;

  Future<List<WatchQuote>> call(List<WatchItem> items) =>
      Future.wait([for (final item in items) _load(item)]);

  Future<WatchQuote> _load(WatchItem item) async {
    try {
      final quote = await _source.fetch(item.symbol);
      return WatchQuote(
        item: item,
        quote: quote,
        stats: const MarketStatsCalculator().compute(quote),
      );
    } on MarketDataException {
      return WatchQuote(item: item);
    }
  }
}
