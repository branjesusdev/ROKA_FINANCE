import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showReconcileSheet(BuildContext context) =>
    showFormSheet<void>(context, const ReconcileSheet());

/// "Cuadrar con mi dinero real": escribe cuánto tienes hoy y marca los
/// fijos que ya pagaste. La diferencia queda en el histórico como "gastos
/// sin registrar" (o como saldo inicial si tenías más).
class ReconcileSheet extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ReconcileSheet> createState() => _ReconcileSheetState();
}

class _ReconcileSheetState extends ConsumerState<ReconcileSheet> {
  final _actual = TextEditingController();
  final _paid = <String>{};
  bool _saving = false;

  @override
  void dispose() {
    _actual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(cycleSummaryProvider).value;
    final theme = Theme.of(context);
    final actual = MoneyField.read(_actual);
    final pending = [
      ...?summary?.upcomingFixed.due,
      ...?summary?.upcomingFixed.pending,
    ].where((s) => s.movement.isExpense).toList();
    final paidTotal = Money.sum(
      pending
          .where((s) => _paid.contains(s.movement.id))
          .map((s) => s.movement.amount),
    );
    final registered = summary == null ? null : summary.left - paidTotal;

    return FormSheet(
      title: 'Cuadrar con mi dinero real',
      saveLabel: 'Cuadrar',
      onSave: actual == null || _saving ? null : () => _save(actual),
      children: [
        Text(
          'Suma lo que tienes hoy para gastar: efectivo + cuentas + '
          'billeteras (Nequi, Daviplata…). No incluyas ahorros ni '
          'inversiones.',
          style: theme.textTheme.bodyMedium,
        ),
        MoneyField(
          controller: _actual,
          label: '¿Cuánto dinero tienes hoy?',
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        if (pending.isNotEmpty) ...[
          Text(
            '¿Ya pagaste alguno de estos fijos?',
            style: theme.textTheme.titleSmall,
          ),
          for (final item in pending)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _paid.contains(item.movement.id),
              onChanged: (checked) => setState(
                () => checked ?? false
                    ? _paid.add(item.movement.id)
                    : _paid.remove(item.movement.id),
              ),
              title: Text(item.movement.name),
              subtitle: Text(
                '${Formatters.money(item.movement.amount)} · día '
                '${item.movement.dayOfMonth}',
              ),
            ),
        ],
        if (registered != null && actual != null)
          _Preview(registered: registered, actual: actual),
      ],
    );
  }

  Future<void> _save(Money actual) async {
    setState(() => _saving = true);
    final result = await ref
        .read(reconcileBalanceProvider)
        .call(actual: actual, paidFixedIds: _paid);
    if (!mounted) return;
    setState(() => _saving = false);
    final message = switch (result) {
      Ok(:final value) when value.difference.isZero =>
        'Todo cuadra: tus registros coinciden con tu dinero.',
      Ok(:final value) when value.difference.isNegative =>
        'Listo. ${Formatters.money(value.difference.abs)} quedaron como '
            'gastos sin registrar.',
      Ok(:final value) =>
        'Listo. Se sumaron ${Formatters.money(value.difference)} como saldo.',
      Err() => null,
    };
    if (showResult(context, result, success: message)) {
      Navigator.of(context).pop();
    }
  }
}

class _Preview extends StatelessWidget {
  const new({required this.registered, required this.actual});

  final Money registered;
  final Money actual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difference = actual - registered;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Según tus registros: ${Formatters.money(registered)}'),
            Text('Dinero real: ${Formatters.money(actual)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  difference.isNegative
                      ? Icons.trending_down
                      : difference.isZero
                      ? Icons.check_circle_outline
                      : Icons.trending_up,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    difference.isZero
                        ? 'Todo cuadra.'
                        : difference.isNegative
                        ? '${Formatters.money(difference.abs)} se fueron sin '
                              'registrar. Quedará en el histórico para '
                              'mejorar el próximo ciclo.'
                        : 'Tienes ${Formatters.money(difference)} que no '
                              'estaban registrados. Se suman como saldo (no '
                              'como ingreso).',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Acceso rápido desde el Home.
class ReconcileButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.account_balance_wallet_outlined),
    label: const Text('Cuadrar con mi dinero real'),
    onPressed: () => showReconcileSheet(context),
  );
}
