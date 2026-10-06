import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/presentation/fixed/fixed_movements_screen.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showSettingsSheet(BuildContext context) =>
    showFormSheet<void>(context, const SettingsSheet());

/// Día de pago, recordatorio diario y acceso a los fijos.
class SettingsSheet extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).value ?? const FinanceSettings();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ajustes', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: settings.payday,
            decoration: const InputDecoration(
              labelText: 'Día en que llega tu sueldo',
              helperText: 'Ese día empieza un ciclo nuevo desde cero.',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var d = PayCycle.minPayday; d <= PayCycle.maxPayday; d++)
                DropdownMenuItem(value: d, child: Text('Día $d')),
            ],
            onChanged: (day) async {
              if (day == null) return;
              final result = await ref.read(updatePaydayProvider).call(day);
              if (context.mounted) showResult(context, result);
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Recordatorio diario'),
            subtitle: Text(
              'Te avisa a las ${_hourLabel(settings.reminderHour)} para '
              'registrar gastos e ingresos.',
            ),
            value: settings.dailyReminder,
            onChanged: (enabled) =>
                _updateReminder(context, ref, enabled: enabled),
          ),
          if (settings.dailyReminder)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Hora del recordatorio'),
              trailing: Text(
                _hourLabel(settings.reminderHour),
                style: theme.textTheme.titleMedium,
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: settings.reminderHour,
                    minute: 0,
                  ),
                  helpText: 'Elige la hora (se usa la hora en punto)',
                );
                if (picked == null || !context.mounted) return;
                await _updateReminder(
                  context,
                  ref,
                  enabled: true,
                  hour: picked.hour,
                );
              },
            ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_repeat),
            title: const Text('Gastos e ingresos fijos'),
            subtitle: const Text('Arriendo, colegio, crédito, sueldo…'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
              ..pop()
              ..push(
                MaterialPageRoute<void>(
                  builder: (_) => const FixedMovementsScreen(),
                ),
              ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReminder(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
    int? hour,
  }) async {
    final sync = ref.read(syncDailyReminderProvider);
    final result = await ref
        .read(updateDailyReminderProvider)
        .call(enabled: enabled, hour: hour);
    if (!context.mounted || !showResult(context, result)) return;
    final scheduled = await sync();
    if (!scheduled && enabled && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Activa las notificaciones de la app en los ajustes del teléfono.',
          ),
        ),
      );
    }
  }

  static String _hourLabel(int hour) {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:00 ${hour < 12 ? 'a. m.' : 'p. m.'}';
  }
}
