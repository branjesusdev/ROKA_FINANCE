import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Mi sueldo": lo que llega cada mes. Es la base del SÍ/NO de "¿Puedo
/// gastar…?" y de la proyección de los próximos meses.
class SalarySection extends ConsumerStatefulWidget {
  const new({required this.settings, super.key});

  final FinanceSettings settings;

  @override
  ConsumerState<SalarySection> createState() => _SalarySectionState();
}

class _SalarySectionState extends ConsumerState<SalarySection> {
  late final _salary = TextEditingController(
    text: widget.settings.hasSalary
        ? MoneyField.initial(widget.settings.monthlySalary)
        : '',
  )..addListener(_onChanged);

  bool _justSaved = false;

  Money get _typed => MoneyField.read(_salary) ?? Money.zero;

  bool get _hasChanges => _typed != widget.settings.monthlySalary;

  void _onChanged() => setState(() => _justSaved = false);

  @override
  void dispose() {
    _salary.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final result = await ref.read(updateSalaryProvider).call(_typed);
    if (!mounted) return;
    if (showResult(context, result)) setState(() => _justSaved = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forecast = ref.watch(salaryForecastProvider).value;
    final detected = forecast != null && !widget.settings.hasSalary
        ? forecast.salary
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mi sueldo', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        MoneyField(
          controller: _salary,
          label: 'Sueldo neto que te llega cada mes',
          helperText:
              'Lo que cae en tu cuenta. Con esto "¿Puedo gastar…?" te dice '
              'SÍ o NO y te avisa si vas a estar corto.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (detected != null && detected.isPositive && !_hasChanges)
              ActionChip(
                avatar: const Icon(Icons.auto_awesome, size: 18),
                label: Text('Detectado: ${Formatters.money(detected)}'),
                onPressed: () => _salary.text = MoneyField.initial(detected),
              ),
            if (_hasChanges)
              FilledButton.tonal(
                onPressed: _save,
                child: const Text('Guardar sueldo'),
              )
            else if (_justSaved)
              Semantics(
                liveRegion: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text('Sueldo guardado', style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
          ],
        ),
        if (!widget.settings.hasSalary) ...[
          const SizedBox(height: 4),
          Text(
            'Vacío: lo calculo con lo que registras en Salario.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
