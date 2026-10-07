import 'package:finance_app/application/markets/load_watchlist.dart';
import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/markets/watchlist.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ideas de tecnología, IA y robótica con su comportamiento del último año.
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
          for (final quote in rows) _WatchRow(quote: quote),
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
  const new({required this.quote});

  final WatchQuote quote;

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
