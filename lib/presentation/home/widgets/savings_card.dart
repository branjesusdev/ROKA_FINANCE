import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/domain/savings/savings_target_evaluator.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/traffic_light_badge.dart';
import 'package:flutter/material.dart';

/// Regla de ahorro del mes y meta principal.
class SavingsCard extends StatelessWidget {
  const new({required this.savings, required this.mainGoal, super.key});

  final SavingsStatus savings;
  final GoalProgressItem? mainGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achieved = savings.achieved;
    final goal = mainGoal;

    return SectionCard(
      title: 'Meta de ahorro',
      trailing: savings.target.isPositive
          ? TrafficLightBadge(light: savings.light)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!savings.target.isPositive)
            Text(
              'Registra tus ingresos para calcular tu meta de ahorro '
              '(${Formatters.percent(savings.targetRate)} de lo que ganas).',
              style: theme.textTheme.bodyMedium,
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: LabeledValue(
                    label: 'Meta (${Formatters.percent(savings.targetRate)})',
                    value: Formatters.money(savings.target),
                  ),
                ),
                Expanded(
                  child: LabeledValue(
                    label: 'Ahorrado',
                    value: Formatters.money(savings.actual),
                  ),
                ),
                Expanded(
                  child: LabeledValue(
                    label: 'Falta',
                    value: Formatters.money(savings.remaining),
                  ),
                ),
              ],
            ),
            if (achieved != null) ...[
              const SizedBox(height: 10),
              _Progress(
                fraction: achieved.fraction,
                label: '${Formatters.percent(achieved)} de la meta',
              ),
            ],
          ],
          if (goal != null) ...[
            const Divider(height: 28),
            Text(goal.goal.name, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            _Progress(
              fraction: goal.progress.progress?.fraction ?? 0,
              label:
                  '${Formatters.money(goal.progress.saved)} de '
                  '${Formatters.money(goal.progress.target)}',
            ),
            if (goal.progress.suggestedMonthly case final monthly?) ...[
              const SizedBox(height: 4),
              Text(
                'Para llegar a tiempo: ${Formatters.money(monthly)} al mes.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const new({required this.fraction, required this.label});

  final double fraction;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: fraction.clamp(0, 1).toDouble(),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          semanticsLabel: label,
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
