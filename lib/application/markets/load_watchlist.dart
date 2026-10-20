import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/markets/watch_score.dart';
import 'package:finance_app/domain/markets/watchlist.dart';

/// Instrumento de la lista con su precio, si se pudo consultar.
final class WatchQuote {
  const new({required this.item, this.quote, this.stats, this.score});

  final WatchItem item;
  final MarketQuote? quote;
  final QuoteStats? stats;

  /// Puntaje para ordenar la lista (`null` sin datos de precio).
  final WatchScore? score;

  bool get hasData => quote != null;
}

/// Consulta los precios de la lista y la ordena de mejor a peor puntaje
/// (resultados, crecimiento, volatilidad y riesgo); los que no tienen datos
/// van al final. Un símbolo que falla no tumba los demás.
final class LoadWatchlist {
  const new(this._source);

  final MarketDataSource _source;

  Future<List<WatchQuote>> call(List<WatchItem> items) async =>
      rank(await Future.wait([for (final item in items) _load(item)]));

  /// De mayor a menor puntaje; sin datos al final (orden original).
  static List<WatchQuote> rank(List<WatchQuote> quotes) {
    final indexed = quotes.indexed.toList()
      ..sort((a, b) {
        final sa = a.$2.score?.total ?? -1;
        final sb = b.$2.score?.total ?? -1;
        return sa != sb ? sb.compareTo(sa) : a.$1.compareTo(b.$1);
      });
    return [for (final (_, q) in indexed) q];
  }

  Future<WatchQuote> _load(WatchItem item) async {
    try {
      final quote = await _source.fetch(item.symbol);
      final stats = const MarketStatsCalculator().compute(quote);
      return WatchQuote(
        item: item,
        quote: quote,
        stats: stats,
        score: const WatchScoreCalculator().score(item.kind, stats),
      );
    } on MarketDataException {
      return WatchQuote(item: item);
    }
  }
}
