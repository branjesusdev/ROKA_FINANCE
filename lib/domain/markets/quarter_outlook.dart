import 'dart:math' as math;

import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:meta/meta.dart';

/// Hacia dónde se movió el precio en el último año.
enum TrendDirection { up, flat, down }

/// Qué podría pasar en los próximos 3 meses **si el precio se moviera como
/// en el último año**. Es estadística del pasado, no una predicción: el
/// mercado puede salirse de este rango.
@immutable
final class QuarterOutlook {
  const new({
    required this.typical,
    required this.low,
    required this.high,
    required this.worstQuarter,
    required this.bestQuarter,
    required this.trend,
    required this.level,
  });

  /// Cambio típico en 3 meses (tendencia del último año).
  final Percentage typical;

  /// Rango donde cayeron 2 de cada 3 trimestres (±1 desviación).
  final Percentage low;
  final Percentage high;

  /// Peor y mejor tramo de 13 semanas del último año.
  final Percentage worstQuarter;
  final Percentage bestQuarter;

  final TrendDirection trend;
  final VolatilityLevel level;
}

final class QuarterOutlookCalculator {
  const new();

  static const horizonWeeks = 13;

  /// Mínimo de cierres para que el cálculo tenga sentido (~6 meses).
  static const minCloses = 26;

  /// Tendencia típica por debajo de esto (en valor absoluto) = estable.
  static const flatWithin = Percentage.whole(3);

  /// `null` si no hay suficiente historia.
  QuarterOutlook? compute(MarketQuote quote) {
    final closes = quote.weeklyClosesMinor.where((c) => c > 0).toList();
    // El último cierre semanal suele ser el precio de hoy: no repetirlo.
    if (quote.lastPriceMinor > 0 &&
        (closes.isEmpty || closes.last != quote.lastPriceMinor)) {
      closes.add(quote.lastPriceMinor);
    }
    if (closes.length < minCloses) return null;
    final returns = [
      for (var i = 1; i < closes.length; i++)
        math.log(closes[i] / closes[i - 1]),
    ];
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance =
        returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
        (returns.length - 1);
    final drift = mean * horizonWeeks;
    final spread = math.sqrt(variance) * math.sqrt(horizonWeeks);
    var worst = double.infinity;
    var best = double.negativeInfinity;
    for (var i = 0; i + horizonWeeks < closes.length; i++) {
      final change = closes[i + horizonWeeks] / closes[i] - 1;
      worst = math.min(worst, change);
      best = math.max(best, change);
    }
    final typical = Percentage.fromFraction(math.exp(drift) - 1);
    final annualVolatility = Percentage.fromFraction(
      math.sqrt(variance) * math.sqrt(_weeksPerYear),
    );
    return QuarterOutlook(
      typical: typical,
      low: Percentage.fromFraction(math.exp(drift - spread) - 1),
      high: Percentage.fromFraction(math.exp(drift + spread) - 1),
      worstQuarter: Percentage.fromFraction(worst),
      bestQuarter: Percentage.fromFraction(best),
      trend: typical.basisPoints.abs() < flatWithin.basisPoints
          ? TrendDirection.flat
          : typical.isNegative
          ? TrendDirection.down
          : TrendDirection.up,
      level: annualVolatility >= MarketStatsCalculator.highFrom
          ? VolatilityLevel.high
          : annualVolatility >= MarketStatsCalculator.mediumFrom
          ? VolatilityLevel.medium
          : VolatilityLevel.low,
    );
  }

  static const _weeksPerYear = 52;
}
