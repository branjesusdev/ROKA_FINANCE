import 'dart:async';

import 'package:finance_app/application/reminders/reminder_scheduler.dart';
import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/presentation/categories/categories_screen.dart';
import 'package:finance_app/presentation/fixed/fixed_movements_screen.dart';
import 'package:finance_app/presentation/home/widgets/reconcile_sheet.dart';
import 'package:finance_app/presentation/provisions/provisions_screen.dart';
import 'package:finance_app/presentation/settings/backup_section.dart';
import 'package:finance_app/presentation/settings/household_section.dart';
import 'package:finance_app/presentation/settings/reset_cycle_tile.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showSettingsSheet(BuildContext context) =>
    showFormSheet<void>(context, const SettingsSheet());

/// Estado de los avisos en el teléfono (para explicar si no llegan).
final reminderDiagnosticsProvider =
    FutureProvider.autoDispose<ReminderDiagnostics>(
      (ref) => ref.watch(reminderSchedulerProvider).diagnostics(),
    );

/// Día de pago, avisos y acceso a los fijos.
class SettingsSheet extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).value ?? const FinanceSettings();
    final theme = Theme.of(context);
    final reminderTime = TimeOfDay(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
    );
    return SingleChildScrollView(
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
              labelText: 'Día en que normalmente llega tu sueldo',
              helperText:
                  'Si llega antes o después, regístralo ese día: el ciclo '
                  'nuevo arranca ahí y lo que sobró pasa a ahorro.',
              helperMaxLines: 3,
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
              'Te avisa a las ${reminderTime.format(context)} para registrar '
              'gastos e ingresos.',
            ),
            value: settings.dailyReminder,
            onChanged: (enabled) =>
                _updateReminders(context, ref, enabled: enabled),
          ),
          if (settings.dailyReminder)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Hora del recordatorio'),
              trailing: Text(
                reminderTime.format(context),
                style: theme.textTheme.titleMedium,
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: reminderTime,
                  helpText: 'Elige la hora del recordatorio',
                );
                if (picked == null || !context.mounted) return;
                await _updateReminders(
                  context,
                  ref,
                  enabled: true,
                  hour: picked.hour,
                  minute: picked.minute,
                );
              },
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.tips_and_updates_outlined),
            title: const Text('Avisos inteligentes'),
            subtitle: const Text(
              'Tope del día con una frase (7 a. m.), mediodía, fijos de '
              'mañana, día de pago y cierre de ciclo.',
            ),
            value: settings.smartNotifications,
            onChanged: (enabled) =>
                _updateReminders(context, ref, smart: enabled),
          ),
          const _ReminderStatus(),
          const Divider(),
          HouseholdSection(settings: settings),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Cuadrar con mi dinero real'),
            subtitle: const Text(
              'Escribe cuánto tienes hoy; la diferencia queda en el histórico.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final navigator = Navigator.of(context);
              final parent = navigator.context;
              navigator.pop();
              unawaited(showReconcileSheet(parent));
            },
          ),
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categorías'),
            subtitle: const Text('Crea las tuyas, renómbralas u ocúltalas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
              ..pop()
              ..push(
                MaterialPageRoute<void>(
                  builder: (_) => const CategoriesScreen(),
                ),
              ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month),
            title: const Text('Pagos del año'),
            subtitle: const Text('SOAT, tecnomecánica, gimnasio, colegio…'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
              ..pop()
              ..push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProvisionsScreen(),
                ),
              ),
          ),
          const Divider(),
          const BackupSection(),
          const Divider(),
          const ResetCycleTile(),
        ],
      ),
    );
  }

  Future<void> _updateReminders(
    BuildContext context,
    WidgetRef ref, {
    bool? enabled,
    bool? smart,
    int? hour,
    int? minute,
  }) async {
    final sync = ref.read(syncRemindersProvider);
    final result = await ref
        .read(updateDailyReminderProvider)
        .call(
          enabled: enabled,
          hour: hour,
          minute: minute,
          smartNotifications: smart,
        );
    if (!context.mounted || !showResult(context, result)) return;
    final scheduled = await sync(summary: ref.read(cycleSummaryProvider).value);
    ref.invalidate(reminderDiagnosticsProvider);
    if (!scheduled && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Activa las notificaciones de la app en los ajustes del teléfono.',
          ),
        ),
      );
    }
  }
}

/// Diagnóstico + prueba: si el aviso de prueba llega pero los programados
/// no, el ahorro de batería del teléfono los está bloqueando.
class _ReminderStatus extends ConsumerWidget {
  const new();

  static const _inexactWarning =
      'El teléfono no permite avisos a la hora exacta: pueden llegar tarde. '
      'Actívalo en Ajustes › Apps › Roka › Alarmas y recordatorios.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final diagnostics = ref.watch(reminderDiagnosticsProvider).value;
    final problems = [
      if (diagnostics != null && !diagnostics.notificationsEnabled)
        'Las notificaciones de la app están apagadas en el teléfono.',
      if (diagnostics != null && !diagnostics.exactAlarms) _inexactWarning,
    ];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  problems.isEmpty
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    diagnostics == null
                        ? 'Revisando avisos…'
                        : problems.isEmpty
                        ? '${diagnostics.pending} avisos programados'
                        : 'Hay algo que revisar',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            for (final problem in problems) ...[
              const SizedBox(height: 6),
              Text(problem, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 6),
            Text(
              '¿No llegan? Pon la app en "Sin restricciones" en Ajustes › '
              'Batería (en Xiaomi, Samsung y Huawei también activa el '
              'inicio automático).',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Probar avisos'),
              onPressed: () async {
                final ok = await ref.read(testReminderProvider).call();
                ref.invalidate(reminderDiagnosticsProvider);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Enviamos uno ahora y otro llegará en 1 minuto.'
                          : 'Activa las notificaciones de la app en los '
                                'ajustes del teléfono.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
