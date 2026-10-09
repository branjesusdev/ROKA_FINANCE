import 'package:finance_app/application/dashboard/cycle_pulse.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Así vas este ciclo": tus registros contados en frases cortas. Describe
/// lo que pasó; no es asesoría.
class CyclePulseCard extends ConsumerWidget {
  const new({required this.onSeeAll, super.key});

  final VoidCallback onSeeAll;

  static String _name(Map<String, Category> categories, String id) =>
      categories[id]?.name ?? 'Sin categoría';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulse = ref.watch(cyclePulseProvider).value;
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    return SectionCard(
      title: 'Así vas este ciclo',
      trailing: TextButton(
        onPressed: onSeeAll,
        child: const Text('Movimientos'),
      ),
      child: pulse == null || pulse.isEmpty
          ? Text(
              'Toca + o el micrófono para registrar. Aquí verás en simple '
              'cómo vas.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Column(
              children: [
                _PaceLine(pulse: pulse),
                _Line(
                  icon: Icons.today_outlined,
                  text:
                      'En promedio gastas '
                      '${Formatters.money(pulse.averagePerDay)} al día en el '
                      'día a día.',
                ),
                if (pulse.topCategory case final top?)
                  _Line(
                    icon: Icons.donut_large_outlined,
                    text:
                        '${_name(categories, top.categoryId)}'
                        ' se lleva el ${Formatters.percent(top.share)} de tus '
                        'gastos (${Formatters.money(top.amount)}).',
                  ),
                if (pulse.biggestExpense case final t?)
                  _Line(
                    icon: Icons.arrow_circle_up_outlined,
                    text:
                        'Tu gasto más grande: '
                        '${t.description ?? _name(categories, t.categoryId)}'
                        ', ${Formatters.money(t.amount)} el '
                        '${Formatters.shortDate(t.date)}.',
                  ),
                _Line(
                  icon: Icons.spa_outlined,
                  text:
                      '${pulse.daysWithoutSpending} de ${pulse.daysElapsed} '
                      'días sin gastos del día a día.',
                ),
                if (pulse.busiestWeekday case final weekday?)
                  _Line(
                    icon: Icons.calendar_view_week_outlined,
                    text:
                        'Los ${Formatters.weekdayPlural(weekday)} es cuando '
                        'más gastas.',
                  ),
                _Line(
                  icon: Icons.edit_note,
                  text:
                      'Registraste algo ${pulse.daysRegistered} de '
                      '${pulse.daysElapsed} días.',
                ),
              ],
            ),
    );
  }
}

/// Comparación con el ciclo pasado: color + icono + texto + %.
class _PaceLine extends StatelessWidget {
  const new({required this.pulse});

  final CyclePulse pulse;

  @override
  Widget build(BuildContext context) {
    final change = pulse.changeVsPrevious;
    final spent =
        'Llevas ${Formatters.money(pulse.dayToDaySpent)} en el día a día '
        '(${pulse.daysElapsed} días).';
    if (change == null) {
      return _Line(icon: Icons.payments_outlined, text: spent);
    }
    final share = pulse.changeShare;
    final percent = share == null ? '' : ' (${Formatters.percent(share)})';
    final scheme = Theme.of(context).colorScheme;
    if (change.isZero) {
      return _Line(
        icon: Icons.drag_handle,
        text: '$spent Igual que el ciclo pasado a esta altura.',
      );
    }
    final more = change.isPositive;
    return _Line(
      icon: more ? Icons.trending_up : Icons.trending_down,
      color: more ? scheme.error : TransactionTile.incomeColor,
      text:
          '$spent ${Formatters.money(change.abs)}$percent '
          '${more ? 'más' : 'menos'} que el ciclo pasado a esta altura.',
    );
  }
}

class _Line extends StatelessWidget {
  const new({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
