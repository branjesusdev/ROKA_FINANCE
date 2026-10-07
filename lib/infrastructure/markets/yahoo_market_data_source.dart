import 'dart:convert';
import 'dart:io';

import 'package:finance_app/domain/markets/market_quote.dart';

/// Precios públicos desde el endpoint de gráficos de Yahoo Finance: gratis y
/// sin clave, pero no oficial (puede cambiar). Solo se envía el símbolo
/// consultado; ningún dato del usuario sale del teléfono.
final class YahooMarketDataSource implements MarketDataSource {
  new({HttpClient? client}) : _client = client ?? HttpClient();

  static const _host = 'query1.finance.yahoo.com';
  static const _timeout = Duration(seconds: 12);
  static const _cacheFor = Duration(minutes: 15);
  static const _minorPerUnit = 100;

  final HttpClient _client;
  final _cache = <String, (DateTime, MarketQuote)>{};

  @override
  Future<MarketQuote> fetch(String symbol) async {
    final cached = _cache[symbol];
    final now = DateTime.now();
    if (cached != null && now.difference(cached.$1) < _cacheFor) {
      return cached.$2;
    }
    try {
      final quote = _parse(symbol, await _get(symbol));
      _cache[symbol] = (now, quote);
      return quote;
    } on MarketDataException {
      rethrow;
    } on Exception {
      throw MarketDataException(symbol);
    }
  }

  Future<Map<String, Object?>> _get(String symbol) async {
    final uri = Uri.https(
      _host,
      '/v8/finance/chart/${Uri.encodeComponent(symbol)}',
      {'range': '1y', 'interval': '1wk'},
    );
    final request = await _client.getUrl(uri).timeout(_timeout);
    request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0');
    final response = await request.close().timeout(_timeout);
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      throw MarketDataException(symbol);
    }
    return jsonDecode(body) as Map<String, Object?>;
  }

  MarketQuote _parse(String symbol, Map<String, Object?> json) {
    final results = (json['chart'] as Map<String, Object?>?)?['result'];
    if (results is! List || results.isEmpty) {
      throw MarketDataException(symbol);
    }
    final result = results.first as Map<String, Object?>;
    final meta = result['meta']! as Map<String, Object?>;
    final quotes =
        (result['indicators']! as Map<String, Object?>)['quote']! as List;
    final closes = (quotes.first as Map<String, Object?>)['close'] as List?;
    final price = meta['regularMarketPrice'] as num?;
    if (price == null || closes == null) throw MarketDataException(symbol);
    final time = meta['regularMarketTime'] as int?;
    return MarketQuote(
      symbol: symbol,
      currency: meta['currency'] as String? ?? '',
      lastPriceMinor: (price * _minorPerUnit).round(),
      weeklyClosesMinor: [
        for (final close in closes)
          if (close is num) (close * _minorPerUnit).round(),
      ],
      asOf: time == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(
              time * Duration.millisecondsPerSecond,
            ),
    );
  }
}
