import 'package:finance_app/application/common/money_text.dart';
import 'package:finance_app/application/markets/load_watchlist.dart';
import 'package:finance_app/domain/markets/watch_score.dart';
import 'package:finance_app/domain/markets/watchlist.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';

/// Cuánto quiere invertir el usuario: en pesos o en dólares.
sealed class InvestAmount {
  const new();
}

final class PesosAmount extends InvestAmount {
  const new(this.money);

  final Money money;
}

final class DollarsAmount extends InvestAmount {
  const new(this.cents);

  /// Centavos de dólar.
  final int cents;
}

/// Arma la pregunta para "Tu CFO con IA" con las ideas de IA y robótica ya
/// ordenadas y el monto que el usuario quiere invertir. Solo lleva datos
/// públicos (símbolos y precios) y el monto que el usuario escribe y ve
/// antes de enviar.
abstract final class InvestmentIdeasQuestion {
  /// Ideas incluidas (las mejores del orden): mantiene la pregunta corta.
  static const maxIdeas = 8;

  static String build({
    required List<WatchQuote> ranked,
    required InvestAmount amount,
  }) {
    final ideas = ranked.where((q) => q.score != null).take(maxIdeas);
    final lines = [for (final (i, q) in ideas.indexed) '${i + 1}. ${_line(q)}'];
    final money = _amount(amount);
    final intro =
        'Quiero invertir $money en tecnología, IA y robótica. Esta es la '
        'lista ordenada por la app (puntaje 0-100 que mezcla crecimiento, '
        'volatilidad y diversificación; datos del último año):';
    final ask =
        'Con mis finanzas actuales: 1) ¿Es buen momento para invertir esos '
        '$money o primero debo cubrir fondo de emergencia o deudas? '
        '2) Ordena estas opciones de la más adecuada a la menos para mí, '
        'según resultados, volatilidad, crecimiento y tipo de riesgo. '
        '3) Si fueran $money, ¿a cuál o cuáles los destinarías y en qué '
        'proporción? Explica el riesgo de cada una.';
    return [intro, ...lines, ask].join('\n');
  }

  static String _line(WatchQuote q) {
    final stats = q.stats;
    final score = q.score!;
    return [
      '${q.item.symbol} (${_kind(q.item.kind)}, riesgo ${_risk(score.risk)})',
      'puntaje ${score.total}',
      if (stats?.change1y case final c?) '12m ${_pct(c)}',
      if (stats?.change3m case final c?) '3m ${_pct(c)}',
      if (stats?.volatility case final v?)
        'volatilidad ${v.value.toStringAsFixed(0)}%',
      if (stats?.fromHigh case final h?) 'vs. máximo ${_pct(h)}',
    ].join(', ');
  }

  static String _amount(InvestAmount amount) => switch (amount) {
    PesosAmount(:final money) => MoneyText.format(money),
    DollarsAmount(:final cents) =>
      'US\$ ${(cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2)}',
  };

  static String _pct(Percentage p) =>
      '${p.isNegative ? '' : '+'}${p.value.toStringAsFixed(0)}%';

  static String _kind(WatchKind kind) => switch (kind) {
    WatchKind.broadFund => 'fondo amplio',
    WatchKind.thematicFund => 'fondo temático',
    WatchKind.company => 'empresa',
  };

  static String _risk(RiskType risk) => switch (risk) {
    RiskType.conservative => 'bajo',
    RiskType.moderate => 'medio',
    RiskType.aggressive => 'alto',
    RiskType.veryAggressive => 'muy alto',
  };
}
