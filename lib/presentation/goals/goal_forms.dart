import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Meta nueva ([goal] = null) o edición. El fondo de emergencia usa
/// [EmergencyFundSheet].
class GoalFormSheet extends ConsumerStatefulWidget {
  const new({this.goal, super.key});

  final SavingsGoal? goal;

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  static final _types = GoalType.values.where((t) => t != GoalType.emergency);

  late final _name = TextEditingController(text: widget.goal?.name);
  late final _target = TextEditingController(
    text: MoneyField.initial(widget.goal?.targetAmount),
  );
  late final _monthly = TextEditingController(
    text: MoneyField.initial(widget.goal?.desiredMonthlyContribution),
  );
  late GoalType _type = widget.goal?.type ?? GoalType.travel;
  late DateTime? _date = widget.goal?.targetDate;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _monthly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    return FormSheet(
      title: goal == null ? 'Nueva meta' : 'Editar meta',
      onSave: _save,
      extraActions: [
        if (goal != null)
          TextButton(
            onPressed: () async {
              if (!await confirmDelete(context, 'esta meta')) return;
              final result = await ref.read(deleteGoalProvider)(goal.id);
              if (!context.mounted) return;
              if (showResult(context, result)) Navigator.pop(context);
            },
            child: const Text('Eliminar meta'),
          ),
      ],
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in _types)
              ChoiceChip(
                avatar: Icon(Labels.goalIcon(type), size: 18),
                label: Text(Labels.goal(type)),
                selected: type == _type,
                onSelected: (_) => setState(() {
                  if (_name.text.isEmpty ||
                      _types.any((t) => Labels.goal(t) == _name.text)) {
                    _name.text = type == GoalType.custom
                        ? ''
                        : Labels.goal(type);
                  }
                  _type = type;
                }),
              ),
          ],
        ),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
        ),
        MoneyField(controller: _target, label: 'Valor objetivo'),
        DateTile(
          label: 'Fecha objetivo (opcional)',
          value: _date,
          firstDate: DateTime.now(),
          onChanged: (date) => setState(() => _date = date),
        ),
        MoneyField(
          controller: _monthly,
          label: 'Aporte mensual deseado (opcional)',
        ),
      ],
    );
  }

  Future<void> _save() async {
    final result = await ref
        .read(saveGoalProvider)
        .call(
          id: widget.goal?.id,
          name: _name.text,
          type: _type,
          targetAmount: MoneyField.read(_target) ?? Money.zero,
          targetDate: _date,
          desiredMonthlyContribution: MoneyField.read(_monthly),
        );
    if (mounted && showResult(context, result, success: 'Meta guardada')) {
      Navigator.pop(context);
    }
  }
}

/// Fondo de emergencia: gastos esenciales mensuales × meses objetivo.
class EmergencyFundSheet extends ConsumerStatefulWidget {
  const new({this.goal, super.key});

  final SavingsGoal? goal;

  @override
  ConsumerState<EmergencyFundSheet> createState() => _EmergencyFundSheetState();
}

class _EmergencyFundSheetState extends ConsumerState<EmergencyFundSheet> {
  static const _monthOptions = [3, 6, 12];

  late final _essential = TextEditingController(
    text: MoneyField.initial(
      widget.goal?.emergencyPlan?.essentialMonthlyExpenses,
    ),
  );
  late int _months = widget.goal?.emergencyPlan?.targetMonths ?? 3;

  @override
  void dispose() {
    _essential.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = ref.watch(essentialExpensesSuggestionProvider).value;
    final essential = MoneyField.read(_essential) ?? Money.zero;

    return FormSheet(
      title: 'Fondo de emergencia',
      onSave: _save,
      children: [
        Text(
          'Dinero guardado para imprevistos. Se calcula como tus gastos '
          'esenciales de un mes por el número de meses que quieres cubrir.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        MoneyField(
          controller: _essential,
          label: 'Gastos esenciales al mes',
          helperText: 'Vivienda, alimentación, servicios, transporte, salud.',
          onChanged: (_) => setState(() {}),
        ),
        if (suggestion != null && suggestion.isPositive)
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.auto_awesome, size: 18),
              label: Text('Usar mi promedio: ${Formatters.money(suggestion)}'),
              onPressed: () => setState(
                () => _essential.text = MoneyField.initial(suggestion),
              ),
            ),
          ),
        Text('Meses a cubrir', style: Theme.of(context).textTheme.titleSmall),
        SegmentedButton<int>(
          segments: [
            for (final m in _monthOptions)
              ButtonSegment(value: m, label: Text('$m meses')),
          ],
          selected: {_months},
          onSelectionChanged: (s) => setState(() => _months = s.first),
        ),
        Text(
          'Fondo objetivo: ${Formatters.money(essential.times(_months))}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Future<void> _save() async {
    final result = await ref
        .read(saveGoalProvider)
        .call(
          id: widget.goal?.id,
          name: Labels.goal(GoalType.emergency),
          type: GoalType.emergency,
          targetAmount: Money.zero,
          emergencyPlan: EmergencyPlan(
            essentialMonthlyExpenses: MoneyField.read(_essential) ?? Money.zero,
            targetMonths: _months,
          ),
        );
    if (mounted && showResult(context, result, success: 'Fondo configurado')) {
      Navigator.pop(context);
    }
  }
}

/// Aportar a una meta o retirar de ella.
class ContributionSheet extends ConsumerStatefulWidget {
  const new({required this.item, super.key});

  final GoalProgressItem item;

  @override
  ConsumerState<ContributionSheet> createState() => _ContributionSheetState();
}

class _ContributionSheetState extends ConsumerState<ContributionSheet> {
  late final _amount = TextEditingController(
    text: MoneyField.initial(widget.item.goal.desiredMonthlyContribution),
  );
  bool _withdraw = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: widget.item.goal.name,
      saveLabel: _withdraw ? 'Retirar' : 'Aportar',
      onSave: _save,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Aportar')),
            ButtonSegment(value: true, label: Text('Retirar')),
          ],
          selected: {_withdraw},
          onSelectionChanged: (s) => setState(() => _withdraw = s.first),
        ),
        MoneyField(
          controller: _amount,
          label: 'Valor',
          autofocus: true,
          helperText:
              'Ahorrado: ${Formatters.money(widget.item.progress.saved)}',
        ),
      ],
    );
  }

  Future<void> _save() async {
    final amount = MoneyField.read(_amount) ?? Money.zero;
    final result = await ref
        .read(addContributionProvider)
        .call(
          goalId: widget.item.goal.id,
          amount: _withdraw ? -amount : amount,
        );
    if (mounted &&
        showResult(
          context,
          result,
          success: _withdraw ? 'Retiro registrado' : 'Aporte registrado',
        )) {
      Navigator.pop(context);
    }
  }
}
