import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fijos de valor variable cuyo día llegó: piden el valor real de la
/// factura. Mientras tanto, lo que te queda ya descuenta su estimado.
class PendingBillsCard extends StatelessWidget {
  const new({required this.bills, super.key});

  final List<ScheduledFixed> bills;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Facturas por confirmar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escribe el valor real cuando tengas la factura. Mientras tanto '
            'se descuenta el estimado.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final bill in bills)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(bill.movement.name),
              subtitle: Text(
                '${Formatters.shortDate(bill.date)} · estimado '
                '${Formatters.money(bill.movement.amount)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  showFormSheet<void>(context, ConfirmBillSheet(bill: bill)),
            ),
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
      saveLabel: movement.isExpense ? 'Registrar factura' : 'Registrar',
      onSave: _saving || !(amount?.isPositive ?? false)
          ? null
          : () => _save(amount!),
      children: [
        Text(
          '${movement.isExpense ? 'Vence' : 'Llega'} el '
          '${Formatters.longDate(widget.bill.date)}. El estimado sale del '
          'promedio de tus últimas facturas.',
        ),
        MoneyField(
          controller: _amount,
          label: movement.isExpense ? 'Valor de la factura' : 'Valor recibido',
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
    if (showResult(context, result, success: 'Factura registrada')) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }
}
