import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Al empezar un ciclo nuevo, lo que sobró del anterior se liquida como
/// ahorro. Un toque lo lleva a la meta principal.
class CycleSavingsCard extends ConsumerWidget {
  const new({required this.amount, required this.cycle, super.key});

  final Money amount;

  /// Ciclo actual: un aporte dentro de él cuenta como "ya guardado".
  final PayCycle cycle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goals = ref.watch(goalProgressListProvider).value ?? const [];
    final contributions = ref.watch(contributionsProvider).value ?? const [];
    final saved = contributions.any(
      (c) => c.amount.isPositive && cycle.contains(c.date),
    );
    final target = _target(goals);

    return SectionCard(
      title: 'Ahorro del ciclo anterior',
      trailing: Icon(
        saved ? Icons.check_circle : Icons.savings_outlined,
        color: theme.colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.money(amount),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            saved
                ? 'Ya lo guardaste en tus metas. Así se construye patrimonio.'
                : 'Es lo que te sobró al cerrar el ciclo pasado. No es para '
                      'gastar: muévelo a ahorro o inversión.',
            style: theme.textTheme.bodyMedium,
          ),
          if (!saved) ...[
            const SizedBox(height: 12),
            if (target == null)
              Text(
                'Crea una meta (por ejemplo, fondo de emergencia) en Metas '
                'para guardarlo con un toque.',
                style: theme.textTheme.bodySmall,
              )
            else
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: Text('Guardar en ${target.goal.name}'),
                onPressed: () async {
                  final result = await ref
                      .read(addContributionProvider)
                      .call(goalId: target.goal.id, amount: amount);
                  if (context.mounted) {
                    showResult(
                      context,
                      result,
                      success: 'Guardado en ${target.goal.name}.',
                    );
                  }
                },
              ),
          ],
        ],
      ),
    );
  }

  /// Fondo de emergencia primero; si no, la primera meta sin cumplir.
  GoalProgressItem? _target(List<GoalProgressItem> goals) =>
      goals
          .where(
            (g) => g.goal.type == GoalType.emergency && !g.progress.isCompleted,
          )
          .firstOrNull ??
      goals.where((g) => !g.progress.isCompleted).firstOrNull;
}
