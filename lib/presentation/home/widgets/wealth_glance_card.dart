import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Patrimonio, deudas y metas de un vistazo (el detalle está en Patrimonio
/// y Plan).
class WealthGlanceCard extends ConsumerWidget {
  const new({required this.onOpenWealth, super.key});

  final VoidCallback onOpenWealth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final netWorth = ref.watch(netWorthProvider).value;
    final history = ref.watch(netWorthHistoryProvider).value ?? const [];
    final goals = ref.watch(goalProgressListProvider).value ?? const [];
    if (netWorth == null) return const SizedBox.shrink();
    // Cambio contra el mes anterior registrado.
    final previous = history.length >= 2 ? history[history.length - 2] : null;
    final change = previous == null ? null : netWorth.total - previous.total;
    final active = goals.where((g) => !g.progress.isCompleted).toList()
      ..sort(
        (a, b) => (a.goal.type == GoalType.emergency ? 0 : 1).compareTo(
          b.goal.type == GoalType.emergency ? 0 : 1,
        ),
      );
    return SectionCard(
      title: 'Patrimonio y metas',
      trailing: TextButton(onPressed: onOpenWealth, child: const Text('Ver')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LabeledValue(
                  label: 'Patrimonio neto',
                  value: Formatters.money(netWorth.total),
                ),
              ),
              Expanded(
                child: LabeledValue(
                  label: 'Deudas',
                  value: Formatters.money(netWorth.liabilities),
                ),
              ),
            ],
          ),
          if (change != null && !change.isZero) ...[
            const SizedBox(height: 8),
            _Trend(change: change),
          ],
          for (final item in active.take(2)) ...[
            const SizedBox(height: 12),
            Text(item.goal.name, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (item.progress.progress?.fraction ?? 0)
                  .clamp(0, 1)
                  .toDouble(),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              semanticsLabel: 'Avance de ${item.goal.name}',
              semanticsValue: item.progress.progress == null
                  ? null
                  : Formatters.percent(item.progress.progress!),
            ),
            const SizedBox(height: 2),
            Text(
              '${Formatters.money(item.progress.saved)} de '
              '${Formatters.money(item.progress.target)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (active.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Crea una meta (fondo de emergencia, capital para emprender…) '
              'en Plan › Metas.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Trend extends StatelessWidget {
  const new({required this.change});

  final Money change;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final up = change.isPositive;
    return StatusChip(
      icon: up ? Icons.trending_up : Icons.trending_down,
      label:
          '${up ? 'Subió' : 'Bajó'} ${Formatters.money(change.abs)} vs. el '
          'mes anterior',
      color: up ? StatusColors.okOf(scheme) : scheme.error,
    );
  }
}
