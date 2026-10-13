import 'package:finance_app/application/advisor/windfall_plan.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/cfo/ask_cfo_sheet.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showWindfallSheet(
  BuildContext context, {
  required Money amount,
  required String sourceName,
}) => showFormSheet<void>(
  context,
  WindfallSheet(amount: amount, sourceName: sourceName),
);

/// Propuesta para un ingreso extraordinario (prima, cesantías…). Nada se
/// aplica hasta que el usuario marca y confirma; puede ajustar los montos.
class WindfallSheet extends ConsumerStatefulWidget {
  const new({required this.amount, required this.sourceName, super.key});

  final Money amount;
  final String sourceName;

  @override
  ConsumerState<WindfallSheet> createState() => _WindfallSheetState();
}

class _WindfallSheetState extends ConsumerState<WindfallSheet> {
  /// Índice de la parte → monto elegido (`null` = no aplicar).
  final _chosen = <int, Money>{};
  bool _initialized = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AsyncView(
      value: ref.watch(windfallPlanProvider(widget.amount)),
      builder: (plan) {
        if (!_initialized) {
          _initialized = true;
          for (final (i, slice) in plan.slices.indexed) {
            if (slice.applicable) _chosen[i] = slice.amount;
          }
        }
        return FormSheet(
          title: '¿Qué hacer con tu ${widget.sourceName.toLowerCase()}?',
          saveLabel: _chosen.isEmpty
              ? 'Listo'
              : 'Aplicar ${_chosen.length} '
                    '${_chosen.length == 1 ? 'parte' : 'partes'}',
          onSave: _saving ? null : () => _apply(plan),
          extraActions: [
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Pedir opinión a Tu CFO con IA'),
              onPressed: () =>
                  showAskCfoSheet(context, question: _question(plan)),
            ),
          ],
          children: [
            Text(
              'Recibiste ${Formatters.money(widget.amount)}. No llega cada '
              'mes: úsalo para avanzar, no para sostener gastos. Esta es una '
              'propuesta por prioridades; marca lo que quieras aplicar.',
              style: theme.textTheme.bodyMedium,
            ),
            for (final (i, slice) in plan.slices.indexed)
              _SliceTile(
                slice: slice,
                amount: _chosen[i] ?? slice.amount,
                selected: _chosen.containsKey(i),
                onToggle: slice.applicable
                    ? (on) => setState(
                        () =>
                            on ? _chosen[i] = slice.amount : _chosen.remove(i),
                      )
                    : null,
                onEdit: slice.applicable
                    ? () => _editAmount(i, _chosen[i] ?? slice.amount)
                    : null,
              ),
            Text(
              'Aplicar = aportar a la meta (sale de tu dinero libre como '
              'ahorro) o abonar a la deuda. Lo demás es una guía: inviertes '
              'tú donde elijas y lo registras después.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  String _question(WindfallPlan plan) {
    final parts = plan.slices
        .map((s) => '${_useName(s.use)} ${Formatters.money(s.amount)}')
        .join(', ');
    return 'Recibí ${Formatters.money(widget.amount)} de '
        '${widget.sourceName}. La app propone: $parts. ¿Qué ajustarías y '
        'por qué?';
  }

  Future<void> _editAmount(int index, Money current) async {
    final controller = TextEditingController(text: MoneyField.initial(current));
    final value = await showDialog<Money>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cuánto?'),
        content: MoneyField(
          controller: controller,
          label: 'Monto',
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
      setState(() => _chosen[index] = value);
    }
  }

  Future<void> _apply(WindfallPlan plan) async {
    if (_chosen.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    final slices = [
      for (final MapEntry(key: i, value: amount) in _chosen.entries)
        WindfallSlice(
          use: plan.slices[i].use,
          amount: amount,
          reason: plan.slices[i].reason,
          label: plan.slices[i].label,
          targetId: plan.slices[i].targetId,
        ),
    ];
    final result = await ref.read(applyWindfallSlicesProvider).call(slices);
    if (!mounted) return;
    setState(() => _saving = false);
    if (showResult(context, result, success: 'Listo: plan aplicado')) {
      Navigator.of(context).pop();
    }
  }

  static String _useName(WindfallUse use) => switch (use) {
    WindfallUse.obligations => 'pagos pendientes',
    WindfallUse.emergencyFund => 'fondo de emergencia',
    WindfallUse.debt => 'abono a deuda',
    WindfallUse.goal => 'meta',
    WindfallUse.investment => 'inversión',
    WindfallUse.business => 'capital para emprender',
    WindfallUse.personal => 'gusto personal',
  };
}

class _SliceTile extends StatelessWidget {
  const new({
    required this.slice,
    required this.amount,
    required this.selected,
    required this.onToggle,
    required this.onEdit,
  });

  final WindfallSlice slice;
  final Money amount;
  final bool selected;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (slice.use) {
      WindfallUse.obligations => 'Pagos pendientes del ciclo',
      WindfallUse.emergencyFund => 'Fondo de emergencia',
      WindfallUse.debt => 'Abono a ${slice.label ?? 'tu deuda'}',
      WindfallUse.goal => 'Meta: ${slice.label ?? ''}',
      WindfallUse.investment => 'Invertir a largo plazo',
      WindfallUse.business => 'Capital para emprender',
      WindfallUse.personal => 'Un gusto planeado',
    };
    final icon = switch (slice.use) {
      WindfallUse.obligations => Icons.event_available_outlined,
      WindfallUse.emergencyFund => Icons.health_and_safety_outlined,
      WindfallUse.debt => Icons.credit_card_off_outlined,
      WindfallUse.goal => Icons.flag_outlined,
      WindfallUse.investment => Icons.trending_up,
      WindfallUse.business => Icons.storefront_outlined,
      WindfallUse.personal => Icons.celebration_outlined,
    };
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 4), child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
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
                          if (onEdit != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined, size: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Text(slice.reason, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (onToggle != null)
              Checkbox(
                value: selected,
                onChanged: (on) => onToggle!(on ?? false),
                semanticLabel: 'Aplicar: $title',
              ),
          ],
        ),
      ),
    );
  }
}
