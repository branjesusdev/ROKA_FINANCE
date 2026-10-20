import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/markets/watchlist.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:meta/meta.dart';

/// Tipo de riesgo de un instrumento, del más tranquilo al más movido.
enum RiskType {
  /// Fondo amplio: miles de empresas.
  conservative,

  /// Fondo temático o empresa estable.
  moderate,

  /// Empresa individual o fondo muy volátil.
  aggressive,

  /// Empresa muy volátil: puede caer a la mitad.
  veryAggressive,
}

/// Puntaje descriptivo (0–100) de un instrumento con su último año de
/// precios. Resume resultados, crecimiento, volatilidad y riesgo para
/// ordenar la lista: no es una recomendación ni una predicción.
@immutable
final class WatchScore {
  const new({
    required this.total,
    required this.growth,
    required this.stability,
    required this.risk,
  });

  /// 0–100: más alto = mejor balance entre lo que ha subido y lo que se
  /// mueve.
  final int total;

  /// 0–100: crecimiento a 12 y 3 meses.
  final int growth;

  /// 0–100: qué tan poco se mueve y qué tan cerca está de su máximo.
  final int stability;

  final RiskType risk;
}

final class WatchScoreCalculator {
  const new();

  /// Peso de cada parte del puntaje (suman 100).
  static const growthWeight = 40;
  static const stabilityWeight = 35;
  static const diversificationWeight = 25;

  /// Rangos para pasar cada dato a 0–1 (fuera del rango = extremo).
  static const _year = (min: -0.4, max: 0.8);
  static const _quarter = (min: -0.2, max: 0.3);
  static const _volatility = (min: 0.15, max: 0.7);
  static const _fromHigh = (min: -0.5, max: 0.0);

  /// Peso del año frente al trimestre dentro del crecimiento (de 100).
  static const _yearShare = 70;

  /// `null` si no hay datos de precio.
  WatchScore? score(WatchKind kind, QuoteStats? stats) {
    final change1y = stats?.change1y;
    final volatility = stats?.volatility;
    if (stats == null || change1y == null || volatility == null) return null;
    final year = _scale(change1y, _year);
    final quarter = stats.change3m == null
        ? year
        : _scale(stats.change3m!, _quarter);
    final growth = (year * _yearShare + quarter * (100 - _yearShare)) / 100;
    final calm = 1 - _scale(volatility, _volatility);
    final nearHigh = stats.fromHigh == null
        ? calm
        : _scale(stats.fromHigh!, _fromHigh);
    final stability = (calm * 2 + nearHigh) / 3;
    final spread = switch (kind) {
      WatchKind.broadFund => 1.0,
      WatchKind.thematicFund => 0.7,
      WatchKind.company => 0.35,
    };
    final total =
        growth * growthWeight +
        stability * stabilityWeight +
        spread * diversificationWeight;
    return WatchScore(
      total: total.round().clamp(0, 100),
      growth: (growth * 100).round(),
      stability: (stability * 100).round(),
      risk: riskOf(kind, stats.level),
    );
  }

  /// Riesgo por tipo de instrumento y volatilidad.
  static RiskType riskOf(WatchKind kind, VolatilityLevel? level) =>
      switch ((kind, level)) {
        (WatchKind.broadFund, VolatilityLevel.high) => RiskType.moderate,
        (WatchKind.broadFund, _) => RiskType.conservative,
        (WatchKind.thematicFund, VolatilityLevel.high) => RiskType.aggressive,
        (WatchKind.thematicFund, _) => RiskType.moderate,
        (WatchKind.company, VolatilityLevel.low) => RiskType.moderate,
        (WatchKind.company, VolatilityLevel.high) => RiskType.veryAggressive,
        (WatchKind.company, _) => RiskType.aggressive,
      };

  static double _scale(Percentage value, ({double min, double max}) range) {
    final v = value.fraction;
    return ((v - range.min) / (range.max - range.min)).clamp(0.0, 1.0);
  }
}
