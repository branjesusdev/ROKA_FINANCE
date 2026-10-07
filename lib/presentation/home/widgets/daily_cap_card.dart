import 'package:finance_app/domain/cycles/daily_spending_cap.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/traffic_light_badge.dart';
import 'package:flutter/material.dart';

/// "Hoy puedes gastar": tope del día a día, sin contar los gastos que se
/// planean por mes (mercado, arriendo, servicios…).
class DailyCapCard extends StatelessWidget {
  const new({required this.cap, super.key});

  final DailySpendingCap cap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final color = TrafficLightStyle.color(cap.light, theme.colorScheme);
    final usage = cap.usage;
    final remaining = cap.remainingToday;

    return SectionCard(
      title: 'Tope de hoy',
      trailing: TrafficLightBadge(
        light: cap.light,
        detail: usage == null ? null : '${Formatters.percent(usage)} usado',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cap.exceeded
                ? 'Te pasaste ${Formatters.money(remaining.abs)}'
                : 'Te quedan ${Formatters.money(remaining)} hoy',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cap.exceeded ? color : null,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (usage?.fraction ?? (cap.exceeded ? 1 : 0))
                .clamp(0, 1)
                .toDouble(),
            minHeight: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(5),
            semanticsLabel: 'Tope de hoy usado',
          ),
          const SizedBox(height: 8),
          Text(
            'Tope ${Formatters.money(cap.cap)} · gastado hoy '
            '${Formatters.money(cap.spentToday)}',
            style: theme.textTheme.bodyMedium,
          ),
          if (cap.reserved.isPositive) ...[
            const SizedBox(height: 4),
            Text(
              'Ya apartamos ${Formatters.money(cap.reserved)} para tus gastos '
              'del mes (mercado, servicios…), tus pagos del año y tu ahorro.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            cap.exceeded
                ? 'Lo que pasaste se descuenta de los próximos días. Mañana '
                      'el tope será un poco menor.'
                : 'Almuerzos, transporte, antojos… Mercado, arriendo y '
                      'servicios van aparte, en el presupuesto del mes.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
