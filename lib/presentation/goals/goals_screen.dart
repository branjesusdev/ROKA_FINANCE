import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/presentation/goals/goal_forms.dart';
import 'package:finance_app/presentation/home/widgets/savings_card.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/labels.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Metas: regla de ahorro, fondo de emergencia y metas personales.
class GoalsScreen extends ConsumerWidget {
  const new({super.key});

  static const _spacing = SizedBox(height: 12);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider).value;
    final items = ref.watch(goalProgressListProvider).value ?? const [];
    final emergency = items
        .where((i) => i.goal.type == GoalType.emergency)
        .firstOrNull;
    final others = items.where((i) => i.goal.type != GoalType.emergency);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (summary != null) ...[
          SavingsCard(savings: summary.savings, mainGoal: null),
          const SizedBox(height: 8),
          _SavingsRateSelector(current: summary.savings.targetRate),
        ],
        _spacing,
        SectionCard(
          title: 'Fondo de emergencia',
          trailing: emergency == null
              ? null
              : IconButton(
                  tooltip: 'Configurar',
                  icon: const Icon(Icons.tune),
                  onPressed: () => showFormSheet<void>(
                    context,
                    EmergencyFundSheet(goal: emergency.goal),
                  ),
                ),
          child: emergency == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Un colchón para imprevistos: normalmente entre 3 y 6 '
                      'meses de tus gastos esenciales.',
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => showFormSheet<void>(
                        context,
                        const EmergencyFundSheet(),
                      ),
                      icon: const Icon(Icons.health_and_safety_outlined),
                      label: const Text('Configurar fondo'),
                    ),
                  ],
                )
              : _GoalProgressView(item: emergency),
        ),
        _spacing,
        SectionCard(
          title: 'Mis metas',
          trailing: IconButton.filledTonal(
            tooltip: 'Nueva meta',
            icon: const Icon(Icons.add),
            onPressed: () =>
                showFormSheet<void>(context, const GoalFormSheet()),
          ),
          child: others.isEmpty
              ? const Text(
                  'Crea una meta: un viaje, un vehículo, tu vivienda o lo que '
                  'quieras lograr.',
                )
              : Column(
                  children: [
                    for (final item in others) ...[
                      _GoalProgressView(item: item),
                      if (item != others.last) const Divider(height: 24),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SavingsRateSelector extends ConsumerWidget {
  const new({required this.current});

  static const _options = [5, 10, 15, 20];

  final Percentage current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustom = !_options.any((p) => Percentage.whole(p) == current);
    Future<void> update(Percentage rate) async {
      final result = await ref.read(updateSavingsTargetProvider)(rate);
      if (context.mounted) showResult(context, result);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('¿Cuánto ahorrar?', style: Theme.of(context).textTheme.labelLarge),
        for (final p in _options)
          ChoiceChip(
            label: Text('$p%'),
            selected: Percentage.whole(p) == current,
            onSelected: (_) => update(Percentage.whole(p)),
          ),
        ChoiceChip(
          label: Text(isCustom ? Formatters.percent(current) : 'Personalizado'),
          selected: isCustom,
          onSelected: (_) async {
            final rate = await _askCustomRate(context, current);
            if (rate != null) await update(rate);
          },
        ),
      ],
    );
  }

  static Future<Percentage?> _askCustomRate(
    BuildContext context,
    Percentage current,
  ) {
    final controller = TextEditingController(
      text: PercentField.initial(current),
    );
    return showDialog<Percentage>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Porcentaje de ahorro'),
        content: PercentField(controller: controller, label: 'Porcentaje'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, PercentField.read(controller)),
            child: const Text('Usar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}

String _money(EmergencyPlan plan) =>
    Formatters.money(plan.essentialMonthlyExpenses);

class _GoalProgressView extends StatelessWidget {
  const new({required this.item});

  final GoalProgressItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = item.progress;
    final goal = item.goal;
    final plan = goal.emergencyPlan;
    final percent = progress.progress;
    final details = [
      if (plan != null) '${plan.targetMonths} meses × ${_money(plan)}',
      if (goal.targetDate case final date?)
        'Meta: ${Formatters.longDate(date)}',
      if (progress.isCompleted)
        '¡Meta cumplida!'
      else ...[
        'Faltan ${Formatters.money(progress.remaining)}',
        if (progress.suggestedMonthly case final monthly?)
          'Necesitas ${Formatters.money(monthly)} al mes',
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Labels.goalIcon(goal.type), size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(goal.name, style: theme.textTheme.titleSmall)),
            if (goal.type != GoalType.emergency)
              IconButton(
                tooltip: 'Editar meta',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () =>
                    showFormSheet<void>(context, GoalFormSheet(goal: goal)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent?.fraction.clamp(0, 1).toDouble() ?? 0,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          semanticsLabel: 'Progreso de ${goal.name}',
          semanticsValue: percent == null ? null : Formatters.percent(percent),
        ),
        const SizedBox(height: 6),
        Text(
          '${Formatters.money(progress.saved)} de '
          '${Formatters.money(progress.target)}'
          '${percent == null ? '' : ' (${Formatters.percent(percent)})'}',
          style: theme.textTheme.bodyMedium,
        ),
        Text(details.join(' · '), style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () =>
              showFormSheet<void>(context, ContributionSheet(item: item)),
          icon: const Icon(Icons.savings_outlined),
          label: const Text('Aportar / retirar'),
        ),
      ],
    );
  }
}
