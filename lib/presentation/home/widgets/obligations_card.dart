import 'package:finance_app/application/dashboard/money_overview.dart';
import 'package:finance_app/domain/fixed/fixed_coverage.dart';
import 'package:finance_app/presentation/fixed/fixed_movements_screen.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:flutter/material.dart';

/// Próximos pagos del ciclo con el avance de su reserva: pagado, cubierto,
/// cubierto en parte, sin cubrir o vencido.
class ObligationsCard extends StatelessWidget {
  const new({required this.overview, super.key});

  final MoneyOverview overview;

  /// Pagados que se muestran (los más recientes); el resto queda en Fijos.
  static const maxPaid = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverage = overview.coverage;
    final pending = coverage.pending.toList();
    final paid = coverage.items
        .where((i) => i.state == ObligationState.paid)
        .toList()
        .reversed
        .take(maxPaid)
        .toList();
    final open = TextButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const FixedMovementsScreen()),
      ),
      child: Text(coverage.items.isEmpty ? 'Agregar' : 'Gestionar'),
    );
    if (coverage.items.isEmpty) {
      return SectionCard(
        title: 'Próximos pagos',
        trailing: open,
        child: const Text(
          'Agrega arriendo, servicios, colegio o tu crédito una vez: se '
          'registran solos y la app te dice si te alcanza para cada uno.',
        ),
      );
    }
    return SectionCard(
      title: 'Próximos pagos',
      trailing: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending.isEmpty)
            const Text('Ya pagaste todos los fijos de este ciclo.')
          else ...[
            Text(
              coverage.missing.isPositive
                  ? 'Faltan ${Formatters.money(coverage.missing)} para cubrir '
                        '${Formatters.money(coverage.committed)} en pagos.'
                  : 'Tienes cubiertos los '
                        '${Formatters.money(coverage.committed)} que faltan '
                        'por pagar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in pending) _ObligationRow(item: item),
          ],
          if (paid.isNotEmpty) ...[
            const Divider(height: 24),
            for (final item in paid) _ObligationRow(item: item),
          ],
        ],
      ),
    );
  }
}

class _ObligationRow extends StatelessWidget {
  const new({required this.item});

  final ObligationCoverage item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ObligationStyle.color(item.state, theme.colorScheme);
    final paid = item.state == ObligationState.paid;
    final missing = item.missing.isPositive
        ? ' · faltan ${Formatters.money(item.missing)}'
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.movement.name,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${item.movement.isVariable && !paid ? '≈ ' : ''}'
                '${Formatters.money(item.amount)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              StatusChip(
                icon: ObligationStyle.icon(item.state),
                label: ObligationStyle.label(item.state),
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  paid
                      ? Formatters.shortDate(item.date)
                      : 'Vence ${Formatters.shortDate(item.date)}$missing',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (!paid) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: item.progress.fraction.clamp(0, 1).toDouble(),
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
              semanticsLabel: 'Reserva de ${item.movement.name}',
              semanticsValue: Formatters.percent(item.progress),
            ),
          ],
        ],
      ),
    );
  }
}
