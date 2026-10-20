import 'package:finance_app/application/fixed/fixed_movement_use_cases.dart';
import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/presentation/home/widgets/pending_bills_card.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de un pago sin confirmar: "Vence hoy", "Venció el 12 oct" o "Te
/// recuerdo el 15 oct" si lo pospusiste.
String billStateLabel(ScheduledFixed bill, DateTime now) {
  final movement = bill.movement;
  final until = movement.remindOn;
  if (until != null && movement.isSnoozedOn(now)) {
    return 'Te recuerdo el ${Formatters.shortDate(until)}';
  }
  final today =
      bill.date.year == now.year &&
      bill.date.month == now.month &&
      bill.date.day == now.day;
  final missing = movement.isVariable ? 'falta el valor' : 'sin confirmar';
  return today
      ? 'Vence hoy: $missing'
      : 'Venció el ${Formatters.shortDate(bill.date)}: $missing';
}

/// ✓ Ya lo pagué (escribe el valor) o "Aún no" → mañana / en 2 días.
class BillActions extends ConsumerWidget {
  const new({required this.bill, super.key});

  final ScheduledFixed bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      FilledButton.tonalIcon(
        onPressed: () =>
            showFormSheet<void>(context, ConfirmBillSheet(bill: bill)),
        icon: const Icon(Icons.check),
        label: const Text('Ya lo pagué'),
      ),
      MenuAnchor(
        menuChildren: [
          for (final (days, label) in _snoozeOptions)
            MenuItemButton(
              onPressed: () =>
                  snoozeBill(context, ref, bill.movement, days: days),
              child: Text(label),
            ),
        ],
        builder: (context, controller, _) => OutlinedButton.icon(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.close),
          label: const Text('Aún no'),
        ),
      ),
    ],
  );

  static const _snoozeOptions = [
    (SnoozeFixedBill.tomorrow, 'Recuérdame mañana'),
    (SnoozeFixedBill.inTwoDays, 'Recuérdame en 2 días'),
  ];
}

/// Pospone el aviso de la factura y lo confirma con un mensaje.
Future<void> snoozeBill(
  BuildContext context,
  WidgetRef ref,
  FixedMovement movement, {
  required int days,
}) async {
  final result = await ref
      .read(snoozeFixedBillProvider)
      .call(movement: movement, days: days);
  if (!context.mounted) return;
  showResult(
    context,
    result,
    success: days == SnoozeFixedBill.tomorrow
        ? 'Te recuerdo mañana: ${movement.name}'
        : 'Te recuerdo en $days días: ${movement.name}',
  );
}

/// Abre "Ya lo pagué" de la factura [movementId] (desde una notificación).
/// Si ya no está pendiente, lo dice.
Future<void> confirmBillById(
  BuildContext context,
  WidgetRef ref,
  String movementId,
) async {
  final summary = await ref.read(cycleSummaryProvider.future);
  final now = ref.read(clockProvider).now();
  final day = DateTime(now.year, now.month, now.day);
  final bill = [
    ...summary.upcomingFixed.awaitingAmount,
    // El aviso del día puede llegar antes de que la factura pase a
    // "por confirmar".
    ...summary.upcomingFixed.upcoming.where((s) => !s.date.isAfter(day)),
  ].where((s) => s.movement.id == movementId).firstOrNull;
  if (!context.mounted) return;
  if (bill == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esa factura ya está registrada.')),
    );
    return;
  }
  await showFormSheet<void>(context, ConfirmBillSheet(bill: bill));
}
