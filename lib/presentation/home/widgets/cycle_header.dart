import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/traffic_light_badge.dart';
import 'package:flutter/material.dart';

/// "Te queda" del sueldo en el ciclo actual, en grande.
class CycleHeader extends StatelessWidget {
  const new({required this.summary, super.key});

  final CycleSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final cycle = summary.cycle;
    final left = summary.left;
    final light = summary.usageLight;
    final spent = summary.spentShare;
    final daily = summary.dailyAllowance;
    final previous = summary.previousLeft;

    return Column(
      children: [
        Text(
          'Te queda de tu sueldo',
          style: theme.textTheme.titleMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            Formatters.money(left),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: left.isNegative ? theme.colorScheme.error : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ciclo ${Formatters.shortDate(cycle.start)} – '
          '${Formatters.shortDate(cycle.lastDay)} · '
          '${_daysLeftText(summary.daysLeft)}',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
              icon: Icons.arrow_downward,
              text: 'Ingresos ${Formatters.money(summary.income)}',
            ),
            _Pill(
              icon: Icons.arrow_upward,
              text: 'Gastado ${Formatters.money(summary.outflow)}',
            ),
            if (light != null && spent != null)
              TrafficLightBadge(
                light: light,
                detail: '${Formatters.percent(spent)} usado',
              ),
          ],
        ),
        if (summary.income.isZero) ...[
          const SizedBox(height: 12),
          Text(
            'Registra tu sueldo (o créalo como fijo) para ver cuánto te '
            'queda.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
        if (daily != null) ...[
          const SizedBox(height: 12),
          Text(
            'Para llegar al próximo pago con lo que queda (después de fijos): '
            'unos ${Formatters.money(daily)} por día.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
        if (previous != null) ...[
          const SizedBox(height: 4),
          Text(
            'El ciclo pasado te quedaron ${Formatters.money(previous)}.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }

  static String _daysLeftText(int days) => switch (days) {
    0 => 'ciclo cerrado',
    1 => 'último día',
    _ => 'quedan $days días',
  };
}

class _Pill extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
