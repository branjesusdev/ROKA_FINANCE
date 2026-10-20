import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/fixed/bill_actions.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fijos cuyo día llegó y esperan "Ya lo pagué" (las facturas variables
/// piden su valor real). Mientras tanto, lo que te queda ya los descuenta.
class PendingBillsCard extends ConsumerWidget {
  const new({required this.bills, super.key});

  final List<ScheduledFixed> bills;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).now();
    return SectionCard(
      title: 'Pagos por confirmar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Ya los pagaste? Confírmalo o pospón el aviso. Mientras tanto '
            'ya están descontados de lo que te queda.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final bill in bills) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(bill.movement.name),
              subtitle: Text(
                '${billStateLabel(bill, now)} · '
                '${bill.movement.isVariable ? 'estimado ' : ''}'
                '${Formatters.money(bill.movement.amount)}',
              ),
              onTap: () =>
                  showFormSheet<void>(context, ConfirmBillSheet(bill: bill)),
            ),
            BillActions(bill: bill),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Valor real de una factura, prellenado con el estimado.
class ConfirmBillSheet extends ConsumerStatefulWidget {
  const new({required this.bill, super.key});

  final ScheduledFixed bill;

  @override
  ConsumerState<ConfirmBillSheet> createState() => _ConfirmBillSheetState();
}

class _ConfirmBillSheetState extends ConsumerState<ConfirmBillSheet> {
  late final _amount = TextEditingController(
    text: MoneyField.initial(widget.bill.movement.amount),
  );
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movement = widget.bill.movement;
    final amount = MoneyField.read(_amount);
    return FormSheet(
      title: movement.name,
      saveLabel: !movement.isExpense
          ? 'Registrar'
          : movement.isVariable
          ? 'Registrar factura'
          : 'Ya lo pagué',
      onSave: _saving || !(amount?.isPositive ?? false)
          ? null
          : () => _save(amount!),
      children: [
        Text(
          '${movement.isExpense ? 'Vence' : 'Llega'} el '
          '${Formatters.longDate(widget.bill.date)}. '
          '${movement.isVariable ? 'El estimado sale del promedio de tus '
                    'últimas facturas.' : 'Si pagaste otro valor, cámbialo.'}',
        ),
        MoneyField(
          controller: _amount,
          label: !movement.isExpense
              ? 'Valor recibido'
              : movement.isVariable
              ? 'Valor de la factura'
              : 'Valor pagado',
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Future<void> _save(Money amount) async {
    setState(() => _saving = true);
    final result = await ref
        .read(confirmVariableFixedProvider)
        .call(
          movement: widget.bill.movement,
          scheduledDate: widget.bill.date,
          amount: amount,
        );
    if (!mounted) return;
    if (showResult(context, result, success: 'Pago registrado')) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }
}
