import 'dart:async';

import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/insights/category_report_screen.dart';
import 'package:finance_app/presentation/quick_entry/quick_entry_sheet.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showTransactionPreview(
  BuildContext context, {
  required Transaction transaction,
  required Category? category,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => TransactionPreviewSheet(
    transaction: transaction,
    category: category,
    // El formulario se abre desde quien abrió la vista previa.
    onEdit: () => showQuickEntrySheet(context, editing: transaction),
  ),
);

/// Vista de solo lectura de un movimiento. Editar abre el formulario de
/// siempre; así un toque no cambia nada por accidente.
class TransactionPreviewSheet extends ConsumerWidget {
  const new({
    required this.transaction,
    required this.category,
    required this.onEdit,
    super.key,
  });

  static const incomeColor = Color(0xFF2E7D32);

  final Transaction transaction;
  final Category? category;
  final Future<void> Function() onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = transaction;
    final linked = _linkedTo(ref);
    final sign = t.isIncome ? '+' : '-';
    final rows = <(IconData, String, String)>[
      (Icons.event, 'Fecha', Formatters.longDate(t.date)),
      (Icons.category_outlined, 'Categoría', category?.name ?? 'Sin categoría'),
      if (t.nature case final nature?)
        (
          Icons.tune,
          'Tipo de gasto',
          nature == ExpenseNature.essential ? 'Esencial' : 'Gusto o antojo',
        ),
      if (linked != null) (Icons.link, 'Viene de', linked),
      if (t.odometerKm case final km?)
        (Icons.speed, 'Kilometraje', '${Formatters.pesos(km)} km'),
      if (t.notes case final notes?) (Icons.notes, 'Notas', notes),
      (
        Icons.history,
        'Anotado',
        '${Formatters.shortDate(t.createdAt)} ${_time(t.createdAt)}',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CategoryAvatar(category: category, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.description ?? category?.name ?? 'Movimiento',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        t.isIncome ? 'Ingreso' : 'Gasto',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$sign${Formatters.money(t.amount)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: t.isIncome ? incomeColor : null,
              ),
            ),
            const SizedBox(height: 8),
            for (final (icon, label, value) in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(icon, size: 20),
                title: Text(label, style: theme.textTheme.labelMedium),
                subtitle: Text(value, style: theme.textTheme.bodyLarge),
              ),
            if (t.isLinked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Está ligado a un fijo, deuda o apartado: cambiarlo también '
                  'cambia ese saldo.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (category case final c?)
              TextButton.icon(
                icon: const Icon(Icons.insights),
                label: Text('Ver análisis de ${c.name}'),
                onPressed: () {
                  final navigator = Navigator.of(context);
                  final parent = navigator.context;
                  navigator.pop();
                  unawaited(openCategoryReport(parent, c.id));
                },
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                    onPressed: () => _delete(context, ref),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      unawaited(onEdit());
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _time(DateTime d) =>
      '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

  /// Nombre del fijo, deuda o apartado del que viene (si existe).
  String? _linkedTo(WidgetRef ref) {
    final t = transaction;
    if (t.fixedMovementId case final id?) {
      final fixed = ref.watch(fixedMovementsProvider).value ?? const [];
      final name = fixed.where((m) => m.id == id).firstOrNull?.name;
      return 'Fijo: ${name ?? 'eliminado'}';
    }
    if (t.debtId case final id?) {
      final debts = ref.watch(debtsProvider).value ?? const [];
      final name = debts.where((d) => d.id == id).firstOrNull?.name;
      return 'Deuda: ${name ?? 'eliminada'}';
    }
    if (t.provisionId case final id?) {
      final provisions = ref.watch(provisionsProvider).value ?? const [];
      final name = provisions.where((p) => p.id == id).firstOrNull?.name;
      return 'Pago del año: ${name ?? 'eliminado'}';
    }
    return null;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmDelete(context, 'este movimiento')) return;
    final useCase = ref.read(deleteTransactionProvider);
    final result = await useCase(transaction.id);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Movimiento eliminado'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () => useCase.undo(transaction),
            ),
          ),
        );
      case Err(:final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(failureMessage(failure))),
        );
    }
  }
}
