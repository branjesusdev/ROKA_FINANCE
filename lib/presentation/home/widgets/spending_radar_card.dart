import 'package:finance_app/application/dashboard/spending_radar.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:finance_app/presentation/home/widgets/spending_radar_chart.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _RadarView { categories, weekdays }

/// "Tu huella de gasto": la forma de tus gastos variables este ciclo
/// encima de la del ciclo pasado a la misma altura. Si la forma crece
/// hacia un lado, ahí cambió tu hábito. Solo describe; no aconseja.
class SpendingRadarCard extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SpendingRadarCard> createState() => _SpendingRadarCardState();
}

class _SpendingRadarCardState extends ConsumerState<SpendingRadarCard> {
  _RadarView _view = _RadarView.categories;

  @override
  Widget build(BuildContext context) {
    final radar = ref.watch(spendingRadarProvider).value;
    if (radar == null || radar.isEmpty) return const SizedBox.shrink();
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final view = radar.byCategory.isEmpty ? _RadarView.weekdays : _view;
    final axes = view == _RadarView.categories
        ? radar.byCategory
        : radar.byWeekday;
    String name(RadarAxis axis) => view == _RadarView.categories
        ? categories[axis.key]?.name ?? 'Sin categoría'
        : Formatters.weekdayShort(int.parse(axis.key));
    String longName(RadarAxis axis) => view == _RadarView.categories
        ? name(axis)
        : 'Los ${Formatters.weekdayPlural(int.parse(axis.key))}';

    String describe(RadarAxis a) =>
        '${longName(a)}: ${Formatters.money(a.current)} este ciclo, '
        '${Formatters.money(a.previous)} el pasado';

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentColor = isDark ? AppTheme.accent : AppTheme.forest;
    final previousColor = scheme.onSurfaceVariant;

    return SectionCard(
      title: 'Tu huella de gasto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'La forma de tus gastos del día a día (sin fijos) en '
            '${radar.daysElapsed} días, frente al ciclo pasado en los '
            'mismos días.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (radar.byCategory.isNotEmpty) ...[
            const SizedBox(height: 12),
            SegmentedButton<_RadarView>(
              segments: const [
                ButtonSegment(
                  value: _RadarView.categories,
                  label: Text('En qué'),
                  icon: Icon(Icons.donut_large_outlined),
                ),
                ButtonSegment(
                  value: _RadarView.weekdays,
                  label: Text('Qué día'),
                  icon: Icon(Icons.calendar_view_week_outlined),
                ),
              ],
              selected: {view},
              onSelectionChanged: (s) => setState(() => _view = s.first),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: SpendingRadarChart(
              labels: [for (final a in axes) name(a)],
              current: [for (final a in axes) a.current.cents.toDouble()],
              previous: [for (final a in axes) a.previous.cents.toDouble()],
              currentColor: currentColor,
              previousColor: previousColor,
              semanticsLabel: [for (final a in axes) describe(a)].join('. '),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              _Legend(color: currentColor, text: 'Este ciclo'),
              if (radar.hasPrevious)
                _Legend(
                  color: previousColor,
                  text: 'Ciclo pasado',
                  dashed: true,
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._insights(context, axes, longName, radar.hasPrevious),
        ],
      ),
    );
  }

  List<Widget> _insights(
    BuildContext context,
    List<RadarAxis> axes,
    String Function(RadarAxis) name,
    bool hasPrevious,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final strongest = SpendingRadar.strongest(axes);
    final rise = hasPrevious ? SpendingRadar.biggestRise(axes) : null;
    final drop = hasPrevious ? SpendingRadar.biggestDrop(axes) : null;
    String percent(RadarAxis a) => switch (a.changeShare) {
      final share? => ' (${Formatters.percent(share)})',
      null => '',
    };
    return [
      if (strongest != null)
        _Insight(
          icon: Icons.my_location,
          text:
              '${name(strongest)} es la punta de tu huella: '
              '${Formatters.money(strongest.current)}.',
        ),
      if (rise != null)
        _Insight(
          icon: Icons.trending_up,
          color: scheme.error,
          text: rise.previous.isZero
              ? '${name(rise)}: ${Formatters.money(rise.current)} nuevo; '
                    'el ciclo pasado no había gasto aquí.'
              : '${name(rise)} creció ${Formatters.money(rise.change)}'
                    '${percent(rise)} frente al ciclo pasado.',
        ),
      if (drop != null)
        _Insight(
          icon: Icons.trending_down,
          color: TransactionTile.incomeColor,
          text:
              '${name(drop)} bajó ${Formatters.money(-drop.change)}'
              '${percent(drop)} frente al ciclo pasado.',
        ),
      if (hasPrevious && rise == null && drop == null)
        const _Insight(
          icon: Icons.drag_handle,
          text: 'Tu huella es igual a la del ciclo pasado.',
        ),
    ];
  }
}

class _Legend extends StatelessWidget {
  const new({required this.color, required this.text, this.dashed = false});

  final Color color;
  final String text;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          dashed ? Icons.more_horiz : Icons.horizontal_rule,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _Insight extends StatelessWidget {
  const new({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
