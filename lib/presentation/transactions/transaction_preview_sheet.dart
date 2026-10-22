import 'dart:async';

import 'package:finance_app/application/transactions/movement_history.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/insights/category_report_screen.dart';
import 'package:finance_app/presentation/quick_entry/quick_entry_sheet.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/monthly_histogram.dart';
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
            const SizedBox(height: 12),
            _HistoryCard(transaction: t, category: category),
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

/// Análisis de 12 meses de lo mismo que este movimiento: solo esa
/// descripción o toda su categoría (p. ej. toda Alimentación), en barras o
/// línea; tocar un mes muestra su detalle.
class _HistoryCard extends ConsumerStatefulWidget {
  const new({required this.transaction, required this.category});

  final Transaction transaction;
  final Category? category;

  @override
  ConsumerState<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends ConsumerState<_HistoryCard> {
  MovementHistoryBasis? _basis;
  HistogramStyle _style = HistogramStyle.bars;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final history = ref.watch(movementHistoryProvider((t, _basis))).value;
    if (history == null || history.count == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final peak = history.peak!;
    final average = history.monthlyAverage;
    final categoryName = widget.category?.name ?? 'la categoría';
    final byDescription = history.basis == MovementHistoryBasis.description;
    final what = byDescription
        ? '"${t.description!.trim()}"'
        : 'Toda $categoryName';
    final selected = _selected == null ? null : history.months[_selected!];
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$what en 12 meses',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (history.canGroupByDescription) ...[
              const SizedBox(height: 8),
              SegmentedButton<MovementHistoryBasis>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: MovementHistoryBasis.description,
                    icon: const Icon(Icons.label_outline),
                    label: Text(
                      t.description!.trim(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ButtonSegment(
                    value: MovementHistoryBasis.category,
                    icon: const Icon(Icons.category_outlined),
                    label: Text(
                      'Toda $categoryName',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                selected: {history.basis},
                onSelectionChanged: (s) => setState(() {
                  _basis = s.first;
                  _selected = null;
                }),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected == null
                        ? 'Toca un mes para ver su detalle'
                        : '${Formatters.month(selected.month)}: '
                              '${Formatters.money(selected.total)} · '
                              '${selected.count} '
                              '${selected.count == 1 ? 'vez' : 'veces'}',
                    style: selected == null
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                  ),
                ),
                IconButton(
                  tooltip: _style == HistogramStyle.bars
                      ? 'Ver como línea'
                      : 'Ver como barras',
                  icon: Icon(
                    _style == HistogramStyle.bars
                        ? Icons.show_chart
                        : Icons.bar_chart,
                  ),
                  onPressed: () => setState(
                    () => _style = _style == HistogramStyle.bars
                        ? HistogramStyle.line
                        : HistogramStyle.bars,
                  ),
                ),
              ],
            ),
            MonthlyHistogram(
              months: history.months,
              peak: peak,
              average: average,
              style: _style,
              selected: _selected,
              onSelect: (i) => setState(() => _selected = i),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (average != null)
                  const _Legend(label: 'Promedio', dashed: true),
                _Legend(label: 'Este mes', color: theme.colorScheme.primary),
                const _Legend(
                  label: 'Mes más alto',
                  color: MonthlyHistogram.peakColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatsGrid(history: history, isIncome: t.isIncome),
          ],
        ),
      ),
    );
  }
}

/// Los números que completan la gráfica: total, promedio, extremos, valor
/// por vez, este mes frente al promedio y tendencia.
class _StatsGrid extends StatelessWidget {
  const new({required this.history, required this.isIncome});

  final MovementHistory history;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peak = history.peak!;
    final lowest = history.lowest!;
    final vsAverage = history.currentVsAverage;
    final trend = history.trend;
    final times = history.count == 1 ? 'vez' : 'veces';
    final stats = <(IconData, String, String, Color?)>[
      (
        Icons.functions,
        'Total 12 meses',
        '${Formatters.money(history.total)} · ${history.count} $times',
        null,
      ),
      if (history.monthlyAverage case final avg?)
        (
          Icons.horizontal_rule,
          'Promedio por mes',
          '${Formatters.money(avg)} (${history.activeMonths} meses)',
          null,
        ),
      (
        Icons.arrow_upward,
        'Mes más alto',
        '${Formatters.month(peak.month)} · ${Formatters.money(peak.total)}',
        null,
      ),
      (
        Icons.arrow_downward,
        'Mes más bajo',
        '${Formatters.month(lowest.month)} · '
            '${Formatters.money(lowest.total)}',
        null,
      ),
      if (history.averageTicket case final ticket?)
        (
          Icons.receipt_outlined,
          'Cada vez, en promedio',
          Formatters.money(ticket),
          null,
        ),
      if (vsAverage != null)
        _compare(
          theme,
          'Este mes vs. promedio',
          '${Formatters.money(history.current.total)} · ',
          vsAverage,
        ),
      if (trend != null)
        _compare(theme, 'Últimos 3 meses vs. 3 anteriores', '', trend),
    ];
    return Column(
      children: [
        for (final (icon, label, value, color) in stats)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color ?? theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelLarge?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Subir en gastos es alerta (rojo) y en ingresos es bueno (verde).
  (IconData, String, String, Color?) _compare(
    ThemeData theme,
    String label,
    String prefix,
    Percentage change,
  ) {
    final up = change.basisPoints > 0;
    final color = change.basisPoints == 0
        ? null
        : up == isIncome
        ? TransactionPreviewSheet.incomeColor
        : theme.colorScheme.error;
    final word = change.basisPoints == 0
        ? 'igual'
        : up
        ? 'subió'
        : 'bajó';
    final amount = Formatters.percent(
      Percentage.basisPoints(change.basisPoints.abs()),
    );
    return (
      up ? Icons.trending_up : Icons.trending_down,
      label,
      '$prefix$word $amount',
      color,
    );
  }
}

class _Legend extends StatelessWidget {
  const new({required this.label, this.color, this.dashed = false});

  final String label;
  final Color? color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          Text(
            '- -',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
