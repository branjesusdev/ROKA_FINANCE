import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Mi hogar": hijos a cargo y si eres el único ingreso. La app ajusta el
/// fondo de emergencia sugerido, protege un apartado para imprevistos de
/// los niños en el tope diario y prioriza el fondo en el plan del sobrante.
class HouseholdSection extends ConsumerStatefulWidget {
  const new({required this.settings, super.key});

  final FinanceSettings settings;

  @override
  ConsumerState<HouseholdSection> createState() => _HouseholdSectionState();
}

class _HouseholdSectionState extends ConsumerState<HouseholdSection> {
  late final _buffer = TextEditingController(
    text: widget.settings.kidsMonthlyBuffer.isPositive
        ? MoneyField.initial(widget.settings.kidsMonthlyBuffer)
        : '',
  )..addListener(_onBufferChanged);

  /// Tras guardar se muestra "Guardado" en lugar del botón (el SnackBar
  /// quedaría detrás de la hoja de ajustes); al editar vuelve el botón.
  bool _justSaved = false;

  Money get _typedBuffer => MoneyField.read(_buffer) ?? Money.zero;

  bool get _hasChanges => _typedBuffer != widget.settings.kidsMonthlyBuffer;

  void _onBufferChanged() => setState(() => _justSaved = false);

  @override
  void dispose() {
    _buffer.dispose();
    super.dispose();
  }

  Future<void> _saveBuffer() async {
    FocusScope.of(context).unfocus();
    final result = await ref
        .read(updateHouseholdProvider)
        .call(kidsMonthlyBuffer: _typedBuffer);
    if (!mounted) return;
    if (showResult(context, result)) setState(() => _justSaved = true);
  }

  Future<void> _update({int? dependents, bool? soloProvider}) async {
    final result = await ref
        .read(updateHouseholdProvider)
        .call(dependents: dependents, soloProvider: soloProvider);
    if (mounted) showResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.settings;
    final income = ref.watch(cycleSummaryProvider).value?.income;
    final suggestion = income == null || !income.isPositive
        ? null
        : income
              .applyPercentage(FinanceSettings.suggestedKidsBufferPerChild)
              .times(settings.dependents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mi hogar', style: theme.textTheme.titleMedium),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.child_care),
          title: const Text('Hijos a cargo'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Quitar uno',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: settings.dependents == 0
                    ? null
                    : () => _update(dependents: settings.dependents - 1),
              ),
              Text(
                '${settings.dependents}',
                style: theme.textTheme.titleMedium,
              ),
              IconButton(
                tooltip: 'Agregar uno',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _update(dependents: settings.dependents + 1),
              ),
            ],
          ),
        ),
        if (settings.hasDependents) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.person_outline),
            title: const Text('Sostengo el hogar solo/a'),
            subtitle: const Text(
              'Sin aporte de la otra parte ni otro ingreso en casa.',
            ),
            value: settings.soloProvider,
            onChanged: (solo) => _update(soloProvider: solo),
          ),
          MoneyField(
            controller: _buffer,
            label: 'Apartado mensual para imprevistos de los niños',
            helperText:
                'Salud, colegio, ropa… Se protege del tope diario. Lo que '
                'gastes en Hijos/Familia lo va usando.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (suggestion != null)
                ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 18),
                  label: Text('Sugerido: ${Formatters.money(suggestion)}'),
                  onPressed: () => setState(
                    () => _buffer.text = MoneyField.initial(suggestion),
                  ),
                ),
              if (_hasChanges)
                FilledButton.tonal(
                  onPressed: _saveBuffer,
                  child: const Text('Guardar apartado'),
                )
              else if (_justSaved)
                _SavedBadge(color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Con esto tu fondo de emergencia sugerido sube a '
            '${settings.emergencyMonths} meses de gastos esenciales y el plan '
            'del sobrante lo prioriza.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _SavedBadge extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              'Apartado guardado',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
