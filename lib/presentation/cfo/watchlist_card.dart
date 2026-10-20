import 'package:finance_app/application/markets/investment_ideas_question.dart';
import 'package:finance_app/application/markets/load_watchlist.dart';
import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/markets/watch_score.dart';
import 'package:finance_app/domain/markets/watchlist.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/presentation/cfo/ask_cfo_sheet.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ideas de tecnología, IA y robótica con su comportamiento del último año,
/// ordenadas por puntaje (resultados, crecimiento, volatilidad y riesgo).
/// Los precios se consultan solo cuando el usuario lo pide.
class WatchlistCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requested = ref.watch(watchlistRequestProvider) > 0;
    final quotes = ref.watch(watchlistProvider);
    final loaded = quotes.value ?? const <WatchQuote>[];
    final failedAll = loaded.isNotEmpty && loaded.every((q) => !q.hasData);
    final ranked = loaded.any((q) => q.score != null);
    final rows = loaded.isEmpty
        ? [for (final item in TechWatchlist.items) WatchQuote(item: item)]
        : loaded;

    return SectionCard(
      title: 'Ideas para invertir: IA y robótica',
      trailing: IconButton(
        tooltip: requested ? 'Actualizar precios' : 'Consultar precios',
        icon: const Icon(Icons.refresh),
        onPressed: () => ref.read(watchlistRequestProvider.notifier).refresh(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Empresas y fondos para seguir. Las que más se mueven (volátiles) '
            'pueden caer fuerte: que sean una parte pequeña de lo que '
            'inviertes.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          if (!requested)
            FilledButton.tonalIcon(
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Consultar precios (requiere internet)'),
              onPressed: () =>
                  ref.read(watchlistRequestProvider.notifier).refresh(),
            )
          else if (quotes.isLoading)
            const LinearProgressIndicator()
          else if (failedAll)
            const Text(
              'No se pudieron consultar los precios. Revisa tu conexión e '
              'intenta de nuevo.',
            ),
          if (ranked)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Ordenadas de mejor a peor balance: lo que han subido, qué '
                'tanto se mueven y si reparten el riesgo (fondo) o no '
                '(empresa).',
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (final (i, quote) in rows.indexed)
            _WatchRow(quote: quote, rank: quote.score == null ? null : i + 1),
          if (ranked) ...[
            const Divider(height: 24),
            _AskWithAmount(ranked: loaded),
          ],
          const SizedBox(height: 8),
          Text(
            'Precios públicos de Yahoo Finance (gratis, con retraso). Solo se '
            'envía el símbolo, nunca tus datos. Desde Colombia puedes comprar '
            'acciones y ETF del exterior con comisionistas vigilados por la '
            'Superfinanciera. No es una recomendación de compra.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchRow extends StatelessWidget {
  const new({required this.quote, this.rank});

  final WatchQuote quote;

  /// Puesto en el orden (1 = mejor balance).
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = quote.item;
    final stats = quote.stats;
    final data = quote.quote;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (rank case final rank?) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '$rank',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(_kindIcon(item.kind), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.name} · ${item.symbol}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (data != null)
                Text(
                  '${(data.lastPriceMinor / 100).toStringAsFixed(2)} '
                  '${data.currency}',
                  style: theme.textTheme.labelLarge,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(item.why, style: theme.textTheme.bodySmall),
          if (stats != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (quote.score case final score?) ...[
                  _ScoreChip(score: score),
                  _RiskChip(risk: score.risk),
                ],
                if (stats.change1y case final change?)
                  _Stat(label: '12 meses', value: change, signed: true),
                if (stats.change3m case final change?)
                  _Stat(label: '3 meses', value: change, signed: true),
                if (stats.fromHigh case final fromHigh?)
                  _Stat(label: 'vs. máximo', value: fromHigh, signed: true),
                if (stats.level case final level?)
                  _VolatilityChip(level: level, value: stats.volatility),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static IconData _kindIcon(WatchKind kind) => switch (kind) {
    WatchKind.broadFund => Icons.public,
    WatchKind.thematicFund => Icons.hub_outlined,
    WatchKind.company => Icons.precision_manufacturing_outlined,
  };
}

/// Variación con flecha y texto (nunca solo color).
class _Stat extends StatelessWidget {
  const new({required this.label, required this.value, this.signed = false});

  final String label;
  final Percentage value;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final up = !value.isNegative;
    final color = up ? const Color(0xFF15803D) : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$label ${signed && up ? '+' : ''}${Formatters.percent(value)}',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _VolatilityChip extends StatelessWidget {
  const new({required this.level, required this.value});

  final VolatilityLevel level;
  final Percentage? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (level) {
      VolatilityLevel.low => 'Volatilidad baja',
      VolatilityLevel.medium => 'Volatilidad media',
      VolatilityLevel.high => 'Muy volátil',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.show_chart, size: 14),
          const SizedBox(width: 2),
          Text(
            value == null ? label : '$label (${Formatters.percent(value!)})',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

/// Puntaje 0–100 con texto (nunca solo color).
class _ScoreChip extends StatelessWidget {
  const new({required this.score});

  final WatchScore score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onColor = theme.colorScheme.onSecondaryContainer;
    return Semantics(
      label:
          'Puntaje ${score.total} de 100. Crecimiento ${score.growth}, '
          'estabilidad ${score.stability}.',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined, size: 14, color: onColor),
            const SizedBox(width: 2),
            Text(
              'Puntaje ${score.total}/100',
              style: theme.textTheme.labelMedium?.copyWith(
                color: onColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tipo de riesgo con icono y texto.
class _RiskChip extends StatelessWidget {
  const new({required this.risk});

  final RiskType risk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, icon) = switch (risk) {
      RiskType.conservative => ('Riesgo bajo', Icons.shield_outlined),
      RiskType.moderate => ('Riesgo medio', Icons.balance_outlined),
      RiskType.aggressive => ('Riesgo alto', Icons.warning_amber_outlined),
      RiskType.veryAggressive => ('Riesgo muy alto', Icons.bolt_outlined),
    };
    final color = risk == RiskType.veryAggressive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// "¿Cuánto quieres invertir?": arma la pregunta para Tu CFO con IA con la
/// lista ordenada y el monto. La pregunta se ve y se puede editar antes de
/// enviarla.
class _AskWithAmount extends ConsumerStatefulWidget {
  const new({required this.ranked});

  final List<WatchQuote> ranked;

  @override
  ConsumerState<_AskWithAmount> createState() => _AskWithAmountState();
}

class _AskWithAmountState extends ConsumerState<_AskWithAmount> {
  final _amount = TextEditingController();
  bool _dollars = true;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  InvestAmount? get _value {
    if (_dollars) {
      final cents = UsdInput.parse(_amount.text);
      return cents == null || cents <= 0 ? null : DollarsAmount(cents);
    }
    final money = MoneyField.read(_amount);
    return money == null || !money.isPositive ? null : PesosAmount(money);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiEnabled = ref.watch(settingsProvider).value?.aiEnabled ?? false;
    final value = _value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¿Cuánto quieres invertir?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Tu CFO con IA (Groq) mira esta lista y tus totales, y te dice a '
          'cuál o cuáles destinaría ese monto. Verás la pregunta antes de '
          'enviarla.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text(r'Dólares (US$)')),
            ButtonSegment(value: false, label: Text('Pesos')),
          ],
          selected: {_dollars},
          onSelectionChanged: (s) => setState(() {
            _dollars = s.first;
            _amount.clear();
          }),
        ),
        const SizedBox(height: 8),
        if (_dollars)
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto en dólares',
              prefixText: r'US$ ',
              hintText: 'Ej: 200',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          )
        else
          MoneyField(
            controller: _amount,
            label: 'Monto en pesos',
            onChanged: (_) => setState(() {}),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          icon: const Icon(Icons.auto_awesome),
          label: const Text('¿En cuál lo invierto? Pregúntale a Tu CFO'),
          onPressed: !aiEnabled || value == null
              ? null
              : () => showAskCfoSheet(
                  context,
                  question: InvestmentIdeasQuestion.build(
                    ranked: widget.ranked,
                    amount: value,
                  ),
                ),
        ),
        if (!aiEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Activa "Tu CFO con IA" arriba para preguntarle.',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
