import 'dart:async';

import 'package:finance_app/application/markets/value_investments.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/markets/quarter_outlook.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/presentation/cfo/ask_cfo_sheet.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:finance_app/presentation/wealth/wealth_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Cantidad" legible: 2 · 2,5 · 0,013.
String formatUnits(double units) {
  final text = units
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return text.replaceAll('.', ',');
}

/// Hora del día (8:05).
String formatTime(DateTime date) =>
    '${date.hour}:${date.minute.toString().padLeft(2, '0')}';

/// Una acción o fondo con su precio real: cuánto vale hoy, cuánto has ganado
/// de verdad, qué tanto se mueve y qué podría pasar en 3 meses si se moviera
/// como el último año. Descriptivo: no es una recomendación de compra.
class InvestmentDetailSheet extends ConsumerWidget {
  const new({required this.investmentId, super.key});

  final String investmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final market = ref.watch(investmentMarketProvider);
    final investments = ref.watch(investmentsProvider).value ?? const [];
    final stored = investments.where((i) => i.id == investmentId).firstOrNull;
    final view = (market.value ?? const <InvestmentMarketView>[])
        .where((v) => v.investment.id == investmentId)
        .firstOrNull;
    final investment = stored ?? view?.investment;
    if (investment == null) return const SizedBox.shrink();
    final aiEnabled = ref.watch(settingsProvider).value?.aiEnabled ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${investment.name} · ${investment.symbol}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _ValueBlock(investment: investment, view: view),
            const SizedBox(height: 16),
            if (market.isLoading)
              const LinearProgressIndicator()
            else if (view == null || view.failed)
              _NoPrice(failed: view?.failed ?? false)
            else ...[
              if (view.stats case final stats?) _StatsRow(stats: stats),
              const SizedBox(height: 16),
              if (view.outlook case final outlook?)
                _OutlookBlock(view: view, outlook: outlook)
              else
                const Text(
                  'Aún no hay suficiente historia de precios (mínimo 6 '
                  'meses) para estimar los próximos 3 meses.',
                ),
              const SizedBox(height: 16),
              _Reading(view: view),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (aiEnabled && view != null && !view.failed)
                  FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Opinión de Tu CFO con IA'),
                    onPressed: () =>
                        showAskCfoSheet(context, question: _question(view)),
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar precio'),
                  onPressed: market.isLoading
                      ? null
                      : () => ref
                            .read(investmentPricesRequestProvider.notifier)
                            .refresh(),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                  onPressed: () {
                    Navigator.pop(context);
                    unawaited(
                      showFormSheet<void>(
                        context,
                        InvestmentFormSheet(investment: investment),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Basado en el precio público del último año (Yahoo Finance, '
              'con retraso). Solo se consulta el símbolo. Es estadística del '
              'pasado: no es una predicción ni una recomendación de compra o '
              'venta.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pregunta para la IA con datos públicos de la acción (sin montos).
  static String _question(InvestmentMarketView view) {
    final symbol = view.investment.symbol;
    final stats = view.stats;
    final outlook = view.outlook;
    final parts = [
      'Tengo $symbol',
      if (view.share case final share?)
        'y pesa ${Formatters.percent(share)} de mis inversiones',
    ].join(' ');
    final data = [
      if (stats?.change3m case final c?) '3 meses ${_signed(c)}',
      if (stats?.change1y case final c?) '12 meses ${_signed(c)}',
      if (stats?.fromHigh case final c?) 'vs. máximo ${_signed(c)}',
      if (stats?.volatility case final v?)
        'volatilidad anual ${Formatters.percent(v)}',
      if (outlook != null)
        'rango a 3 meses ${_signed(outlook.low)} a ${_signed(outlook.high)}',
    ].join(', ');
    return '$parts ($data). Con mis finanzas actuales, ¿qué me conviene '
        'hacer con esta posición los próximos 3 meses: mantener, aportar '
        'más o reducir? Explica los riesgos.';
  }
}

String _price(MarketQuote q) =>
    '${(q.lastPriceMinor / 100).toStringAsFixed(2)} ${q.currency}';

String _stamp(DateTime d) => '${Formatters.shortDate(d)} ${formatTime(d)}';

String _signed(Percentage p) =>
    '${p.isNegative ? '' : '+'}${Formatters.percent(p)}';

class _ValueBlock extends StatelessWidget {
  const new({required this.investment, required this.view});

  final Investment investment;
  final InvestmentMarketView? view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gain = investment.gain;
    final rate = investment.returnRate;
    final up = !gain.isNegative;
    final color = up
        ? StatusColors.okOf(theme.colorScheme)
        : theme.colorScheme.error;
    final updated = investment.priceUpdatedAt;
    final quote = view?.quote;
    final usd = investment.investedUsdCents;
    final usdValue = quote?.currency.toUpperCase() == 'USD'
        ? view?.quoteValueMinor
        : null;
    final usdReturn = view?.usdReturn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vale hoy', style: theme.textTheme.labelLarge),
        Text(
          Formatters.money(investment.currentValue),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              up ? Icons.trending_up : Icons.trending_down,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${up ? 'Ganancia' : 'Pérdida'} real '
                '${Formatters.money(gain.abs)}'
                '${rate == null ? '' : ' (${_signed(rate)})'} sobre '
                '${Formatters.money(investment.investedAmount)} invertidos',
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
        if (usd != null) ...[
          const SizedBox(height: 4),
          Text(
            [
              'Pagaste ${Formatters.usd(usd)}',
              if (usdValue != null) 'hoy vale ${Formatters.usd(usdValue)}',
              if (usdReturn != null) '${_signed(usdReturn)} en dólares',
            ].join(' · '),
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if ((usdValue, view?.pesosPerQuoteUnit) case (final value?, final rate?)
            when updated != null) ...[
          const SizedBox(height: 4),
          Text(
            '${Formatters.usd(value)} × dólar de hoy '
            '${Formatters.money(rate)} = '
            '${Formatters.money(investment.currentValue)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          [
            if (investment.units case final units?)
              '${formatUnits(units)} unidades',
            if (quote case final q?) 'precio ${_price(q)}',
            if (updated != null)
              'actualizado ${_stamp(updated)}'
            else
              'valor escrito a mano',
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _NoPrice extends StatelessWidget {
  const new({required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context) => Text(
    failed
        ? 'No se pudo consultar el precio. Revisa tu conexión o que el '
              'símbolo esté bien escrito (como aparece en la bolsa).'
        : 'Toca "Actualizar precio" para traer el precio real, la '
              'volatilidad y la lectura de los próximos 3 meses.',
  );
}

class _StatsRow extends StatelessWidget {
  const new({required this.stats});

  final QuoteStats stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (stats.change3m case final c?) _Chip('3 meses ${_signed(c)}', c),
        if (stats.change1y case final c?) _Chip('12 meses ${_signed(c)}', c),
        if (stats.fromHigh case final c?) _Chip('vs. máximo ${_signed(c)}', c),
        if (stats.level case final level?)
          StatusChip(
            icon: Icons.show_chart,
            label: switch (stats.volatility) {
              final v? =>
                '${_volatilityLabel(level)} '
                    '(${Formatters.percent(v)}/año)',
              null => _volatilityLabel(level),
            },
            color: _volatilityColor(level, Theme.of(context).colorScheme),
          ),
      ],
    );
  }
}

String _volatilityLabel(VolatilityLevel level) => switch (level) {
  VolatilityLevel.low => 'Se mueve poco',
  VolatilityLevel.medium => 'Se mueve normal',
  VolatilityLevel.high => 'Muy volátil',
};

Color _volatilityColor(VolatilityLevel level, ColorScheme scheme) =>
    switch (level) {
      VolatilityLevel.low => StatusColors.okOf(scheme),
      VolatilityLevel.medium => StatusColors.infoOf(scheme),
      VolatilityLevel.high => StatusColors.warningOf(scheme),
    };

class _Chip extends StatelessWidget {
  const new(this.label, this.value);

  final String label;
  final Percentage value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final up = !value.isNegative;
    return StatusChip(
      icon: up ? Icons.arrow_upward : Icons.arrow_downward,
      label: label,
      color: up ? StatusColors.okOf(scheme) : scheme.error,
    );
  }
}

class _OutlookBlock extends StatelessWidget {
  const new({required this.view, required this.outlook});

  final InvestmentMarketView view;
  final QuarterOutlook outlook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final low = view.lowIn3m;
    final high = view.highIn3m;
    final loss = view.worstQuarterLoss;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Próximos 3 meses, si se mueve como el último año',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Lo típico: ${_signed(outlook.typical)} '
              '(${switch (outlook.trend) {
                TrendDirection.up => 'viene subiendo',
                TrendDirection.flat => 'sin tendencia clara',
                TrendDirection.down => 'viene bajando',
              }}).',
            ),
            if (low != null && high != null)
              Text(
                '2 de cada 3 veces tu posición quedaría entre '
                '${Formatters.money(low)} y ${Formatters.money(high)} '
                '(${_signed(outlook.low)} a ${_signed(outlook.high)}).',
              ),
            if (loss != null)
              Text(
                'En su peor trimestre del año bajó '
                '${Formatters.percent(outlook.worstQuarter.abs)}: con lo que '
                'tienes serían ${Formatters.money(loss)} menos.',
              ),
          ],
        ),
      ),
    );
  }
}

/// Lectura por reglas, sin IA: qué vigilar y qué hacer.
class _Reading extends StatelessWidget {
  const new({required this.view});

  final InvestmentMarketView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final share = view.share;
    final fromHigh = view.stats?.fromHigh;
    final below = fromHigh == null ? 'muy' : Formatters.percent(fromHigh.abs);
    final items = [
      for (final signal in view.signals)
        switch (signal) {
          InvestmentSignal.concentrated => (
            Icons.pie_chart_outline,
            StatusColors.warningOf(scheme),
            'Pesa ${share == null ? 'mucho' : Formatters.percent(share)} de '
                'tus inversiones. Para bajar el riesgo, que lo nuevo vaya a '
                'algo diversificado (un fondo índice).',
          ),
          InvestmentSignal.volatile => (
            Icons.show_chart,
            StatusColors.warningOf(scheme),
            'Se mueve mucho: aquí solo plata que no vayas a necesitar en '
                'los próximos 3 meses.',
          ),
          InvestmentSignal.farFromHigh => (
            Icons.south_east,
            StatusColors.infoOf(scheme),
            'Está $below por debajo de su máximo del año. Que haya bajado no '
                'significa que vaya a subir: revisa por qué cayó antes de '
                'comprar más.',
          ),
          InvestmentSignal.downTrend => (
            Icons.trending_down,
            scheme.error,
            'Viene bajando: no uses dinero de tus fijos, apartados ni del '
                'fondo de emergencia para comprar más.',
          ),
          InvestmentSignal.upTrend => (
            Icons.trending_up,
            StatusColors.okOf(scheme),
            'Viene subiendo. Si ya ganaste bastante, tomar parte de la '
                'ganancia te protege de depender de una sola acción.',
          ),
        },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lectura de Tu CFO', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        if (items.isEmpty)
          const Text('Sin alertas: se mueve dentro de lo normal.'),
        for (final (icon, color, text) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(text)),
              ],
            ),
          ),
        Text(
          'Regla de oro: invierte solo lo libre, después de fijos, '
          'apartados y fondo de emergencia.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
