import 'package:finance_app/application/dashboard/set_aside_plan.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showSetAsideSheet(BuildContext context) =>
    showFormSheet<void>(context, const SetAsideMoneySheet());

/// "Aparta para no gastarlo": mueve plata a los pagos del año o a tus metas.
/// Nada se mueve hasta que confirmas; puedes cambiar cada monto.
class SetAsideMoneySheet extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SetAsideMoneySheet> createState() => _SetAsideMoneySheetState();
}

class _SetAsideMoneySheetState extends ConsumerState<SetAsideMoneySheet> {
  /// Índice del objetivo → monto elegido.
  final _chosen = <int, Money>{};
  bool _initialized = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AsyncView(
      value: ref.watch(setAsidePlanProvider),
      builder: (plan) {
        if (!_initialized) {
          _initialized = true;
          for (final (i, target) in plan.targets.indexed) {
            if (target.suggested.isPositive) _chosen[i] = target.suggested;
          }
        }
        final total = Money.sum(_chosen.values);
        return FormSheet(
          title: 'Aparta para no gastarlo',
          saveLabel: _chosen.isEmpty
              ? 'Listo'
              : 'Apartar ${Formatters.money(total)}',
          onSave: _saving ? null : () => _apply(plan),
          children: [
            Text(
              plan.free.isPositive
                  ? 'Tienes ${Formatters.money(plan.free)} libres hasta tu '
                        'sueldo. Lo que apartes aquí ya no aparece como '
                        'disponible para el día a día.'
                  : 'Hoy no te sobra dinero libre. Aparta solo lo de tus '
                        'pagos del año, si lo tienes.',
              style: theme.textTheme.bodyMedium,
            ),
            if (plan.isEmpty)
              const Text(
                'No tienes pagos del año pendientes ni metas abiertas. Crea '
                'una meta (por ejemplo, fondo de emergencia) en Plan › Metas.',
              ),
            for (final (i, target) in plan.targets.indexed)
              _TargetTile(
                target: target,
                amount: _chosen[i] ?? target.suggested,
                selected: _chosen.containsKey(i),
                onToggle: (on) => setState(
                  () => on
                      ? _chosen[i] = target.suggested.isPositive
                            ? target.suggested
                            : target.remaining
                      : _chosen.remove(i),
                ),
                onEdit: () => _editAmount(i, target),
              ),
            Text(
              'Apartar crea un movimiento de ahorro (no es un gasto): tu '
              'dinero real no cambia de cuenta, pero la app lo deja fuera de '
              'lo que puedes gastar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editAmount(int index, SetAsideTarget target) async {
    final controller = TextEditingController(
      text: MoneyField.initial(_chosen[index] ?? target.suggested),
    );
    final value = await showDialog<Money>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Cuánto para ${target.name}?'),
        content: MoneyField(
          controller: controller,
          label: 'Monto',
          helperText: 'Le faltan ${Formatters.money(target.remaining)}',
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(MoneyField.read(controller)),
            child: const Text('Usar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isPositive) {
      setState(() => _chosen[index] = value.min(target.remaining));
    }
  }

  Future<void> _apply(SetAsidePlan plan) async {
    if (_chosen.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(applySetAsideProvider).call([
      for (final MapEntry(key: i, value: amount) in _chosen.entries)
        (plan.targets[i], amount),
    ]);
    if (!mounted) return;
    setState(() => _saving = false);
    if (showResult(context, result, success: 'Listo: quedó apartado')) {
      Navigator.of(context).pop();
    }
  }
}

class _TargetTile extends StatelessWidget {
  const new({
    required this.target,
    required this.amount,
    required this.selected,
    required this.onToggle,
    required this.onEdit,
  });

  final SetAsideTarget target;
  final Money amount;
  final bool selected;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProvision = target.provision != null;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                isProvision ? Icons.event_repeat : Icons.flag_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProvision
                        ? 'Pago del año: ${target.name}'
                        : 'Meta: ${target.name}',
                    style: theme.textTheme.titleSmall,
                  ),
                  InkWell(
                    onTap: onEdit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Formatters.money(amount),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined, size: 16),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '${target.reason} Le faltan '
                    '${Formatters.money(target.remaining)}.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (on) => onToggle(on ?? false),
              semanticLabel: 'Apartar para ${target.name}',
            ),
          ],
        ),
      ),
    );
  }
}
