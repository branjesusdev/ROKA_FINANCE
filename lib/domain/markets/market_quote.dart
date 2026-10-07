import 'dart:math' as math;

import 'package:finance_app/domain/shared/percentage.dart';
import 'package:meta/meta.dart';

/// Cotización pública de una acción o fondo. Los precios van en centésimas
/// de la moneda del instrumento (USD, JPY…): son datos de mercado, no
/// dinero del usuario (eso es `Money`, en COP).
@immutable
final class MarketQuote {
  const new({
    required this.symbol,
    required this.currency,
    required this.lastPriceMinor,
    required this.weeklyClosesMinor,
    required this.asOf,
  });

  final String symbol;
  final String currency;
  final int lastPriceMinor;

  /// Cierres semanales del último año, del más antiguo al más reciente.
  final List<int> weeklyClosesMinor;
  final DateTime asOf;
}

/// Qué tanto se mueve el precio.
enum VolatilityLevel { low, medium, high }

/// Lectura descriptiva de una cotización.
@immutable
final class QuoteStats {
  const new({
    required this.change3m,
    required this.change1y,
    required this.fromHigh,
    required this.volatility,
    required this.level,
  });

  final Percentage? change3m;
  final Percentage? change1y;

  /// Distancia al máximo del año (0% o negativo).
  final Percentage? fromHigh;

  /// Volatilidad anualizada de los retornos semanales.
  final Percentage? volatility;
  final VolatilityLevel? level;
}

final class MarketStatsCalculator {
  const new();

  static const _weeksPerYear = 52;
  static const _weeksPerQuarter = 13;

  /// Por debajo: poco volátil. Por encima de [highFrom]: muy volátil.
  static const mediumFrom = Percentage.whole(25);
  static const highFrom = Percentage.whole(45);

  QuoteStats compute(MarketQuote quote) {
    final closes = quote.weeklyClosesMinor.where((c) => c > 0).toList();
    final last = quote.lastPriceMinor;
    if (closes.isEmpty || last <= 0) {
      return const QuoteStats(
        change3m: null,
        change1y: null,
        fromHigh: null,
        volatility: null,
        level: null,
      );
    }
    final high = [...closes, last].reduce(math.max);
    final volatility = _volatility(closes);
    return QuoteStats(
      change3m: closes.length > _weeksPerQuarter
          ? _change(closes[closes.length - 1 - _weeksPerQuarter], last)
          : null,
      change1y: _change(closes.first, last),
      fromHigh: _change(high, last),
      volatility: volatility,
      level: volatility == null
          ? null
          : volatility >= highFrom
          ? VolatilityLevel.high
          : volatility >= mediumFrom
          ? VolatilityLevel.medium
          : VolatilityLevel.low,
    );
  }

  static Percentage _change(int from, int to) =>
      Percentage.fromFraction(to / from - 1);

  static Percentage? _volatility(List<int> closes) {
    if (closes.length < 3) return null;
    final returns = [
      for (var i = 1; i < closes.length; i++) closes[i] / closes[i - 1] - 1,
    ];
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance =
        returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
        (returns.length - 1);
    return Percentage.fromFraction(
      math.sqrt(variance) * math.sqrt(_weeksPerYear),
    );
  }
}

/// No se pudo consultar el precio (sin internet, símbolo inválido…).
final class MarketDataException implements Exception {
  const new(this.symbol);

  final String symbol;

  @override
  String toString() => 'MarketDataException($symbol)';
}

/// Port de precios públicos de mercado. Solo recibe el símbolo: nunca datos
/// del usuario.
abstract interface class MarketDataSource {
  /// Lanza [MarketDataException] si no hay datos.
  Future<MarketQuote> fetch(String symbol);
}
