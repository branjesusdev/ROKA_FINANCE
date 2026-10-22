import 'dart:async';

import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/transactions/cycle_movements.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/cycles/cycle_recount.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/insights/category_report_screen.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/donut_chart.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/motion.dart';
import 'package:finance_app/presentation/shared/recount_badge.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/transaction_tile.dart';
import 'package:finance_app/presentation/transactions/spend_check_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Movimientos por ciclo de sueldo: arriba eliges el ciclo y Gastos o
/// Ingresos; la dona y la lista por categoría muestran en qué se fue; tocar
/// una categoría filtra los movimientos de abajo. Todo sale de los mismos
/// datos ([CycleMovements]), así siempre suma igual.
class TransactionsScreen extends ConsumerStatefulWidget {
  const new({required this.onOpenAnalysis, super.key});

  final VoidCallback onOpenAnalysis;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  /// Ciclos hacia atrás que se pueden ver (los últimos 12 meses).
  static const _maxBack = 11;

  int _back = 0;
  TransactionKind _kind = TransactionKind.expense;
  String? _categoryId;

  /// Hacia dónde se navegó la última vez (para el sentido de la transición).
  var _older = true;

  static const _slideFraction = 0.08;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(cycleMovementsProvider(_back));
    return Column(
      children: [
        _CycleSelector(
          back: _back,
          cycle: data.value?.cycle,
          recount: data.value?.recount,
          canGoBack: _back < _maxBack,
          onChanged: (back) => setState(() {
            _older = back > _back;
            _back = back;
            _categoryId = null;
          }),
        ),
        Expanded(
          // El ciclo entra desde el lado hacia el que se navegó.
          child: AnimatedSwitcher(
            duration: Motion.medium,
            switchInCurve: Motion.emphasized,
            switchOutCurve: Motion.emphasized,
            transitionBuilder: (child, animation) {
              final incoming = child.key == ValueKey(_back);
              final from = (_older == incoming ? -1 : 1) * _slideFraction;
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: Offset(from, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_back),
              child: AsyncView(
                value: data,
                builder: (movements) => _CycleView(
                  movements: movements,
                  kind: _kind,
                  categoryId: _categoryId,
                  onKind: (kind) => setState(() {
                    _kind = kind;
                    _categoryId = null;
                  }),
                  onCategory: (id) => setState(
                    () => _categoryId = _categoryId == id ? null : id,
                  ),
                  onOpenAnalysis: widget.onOpenAnalysis,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CycleSelector extends StatelessWidget {
  const new({
    required this.back,
    required this.cycle,
    required this.recount,
    required this.canGoBack,
    required this.onChanged,
  });

  final int back;
  final PayCycle? cycle;

  /// Reconteo del ciclo: marca su nivel junto al título.
  final CycleRecount? recount;
  final bool canGoBack;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (back) {
      0 => 'Este ciclo',
      1 => 'Ciclo anterior',
      _ => 'Hace $back ciclos',
    };
    final c = cycle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Ciclo anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: canGoBack ? () => onChanged(back + 1) : null,
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (recount case final r?) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: RecountStyle.label(r.level),
                        child: Icon(
                          RecountStyle.icon(r.level),
                          size: 18,
                          color: RecountStyle.color(r.level, theme.colorScheme),
                        ),
                      ),
                    ],
                  ],
                ),
                if (c != null)
                  Text(
                    '${Formatters.shortDate(c.start)} – '
                    '${Formatters.shortDate(c.lastDay)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ciclo siguiente',
            icon: const Icon(Icons.chevron_right),
            onPressed: back > 0 ? () => onChanged(back - 1) : null,
          ),
        ],
      ),
    );
  }
}

class _CycleView extends ConsumerWidget {
  const new({
    required this.movements,
    required this.kind,
    required this.categoryId,
    required this.onKind,
    required this.onCategory,
    required this.onOpenAnalysis,
  });

  final CycleMovements movements;
  final TransactionKind kind;
  final String? categoryId;
  final ValueChanged<TransactionKind> onKind;
  final ValueChanged<String> onCategory;
  final VoidCallback onOpenAnalysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final totals = movements.totalsOf(kind);
    final selected = totals
        .where((t) => t.categoryId == categoryId)
        .firstOrNull;
    final list = movements.filtered(kind, categoryId: categoryId);
    final byDay = <DateTime, List<Transaction>>{};
    for (final t in list) {
      byDay
          .putIfAbsent(
            DateTime(t.date.year, t.date.month, t.date.day),
            () => [],
          )
          .add(t);
    }
    final isExpense = kind == TransactionKind.expense;
    final noun = isExpense ? 'gastos' : 'ingresos';
    final countNoun = list.length == 1 ? 'movimiento' : 'movimientos';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 160),
      children: [
        if (movements.recount case final recount?) ...[
          _RecountCard(recount: recount),
          const SizedBox(height: 12),
        ],
        _KindSelector(movements: movements, kind: kind, onKind: onKind),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerRight,
          child: SpendCheckTextButton(),
        ),
        if (totals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No hay $noun en este ciclo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          )
        else
          _BreakdownCard(
            totals: totals,
            kind: kind,
            selected: selected,
            onCategory: onCategory,
            onOpenAnalysis: selected == null
                ? onOpenAnalysis
                : () => unawaited(
                    openCategoryReport(context, selected.categoryId),
                  ),
          ),
        if (list.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  selected == null
                      ? 'Todos los $noun'
                      : '${selected.category?.name ?? 'Sin categoría'}: '
                            '${list.length} $countNoun',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (selected != null)
                InputChip(
                  label: const Text('Ver todos'),
                  avatar: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  onPressed: () => onCategory(selected.categoryId),
                ),
            ],
          ),
          for (final MapEntry(key: day, value: items) in byDay.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                Formatters.longDate(day),
                style: theme.textTheme.labelLarge,
              ),
            ),
            for (final t in items)
              // Al cambiar Gastos/Ingresos o el filtro, la lista entra de nuevo.
              FadeSlideIn(
                key: ValueKey((kind, selected?.categoryId, t.id)),
                index: list.indexOf(t),
                child: Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: theme.colorScheme.errorContainer,
                    child: const Icon(Icons.delete_outline),
                  ),
                  onDismissed: (_) => _delete(context, ref, t),
                  child: TransactionTile(
                    transaction: t,
                    category: categories[t.categoryId],
                    showDate: false,
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final useCase = ref.read(deleteTransactionProvider);
    final messenger = ScaffoldMessenger.of(context);
    await useCase(transaction.id);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Movimiento eliminado'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => useCase.undo(transaction),
        ),
      ),
    );
  }
}

/// Gastos / Ingresos compacto, con el total de cada uno.
class _KindSelector extends StatelessWidget {
  const new({
    required this.movements,
    required this.kind,
    required this.onKind,
  });

  final CycleMovements movements;
  final TransactionKind kind;
  final ValueChanged<TransactionKind> onKind;

  @override
  Widget build(BuildContext context) {
    final expense = Formatters.money(
      movements.totalOf(TransactionKind.expense),
    );
    final income = Formatters.money(movements.totalOf(TransactionKind.income));
    return SegmentedButton<TransactionKind>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(
          value: TransactionKind.expense,
          icon: const Icon(Icons.arrow_upward, size: 16),
          label: Text('Gastos $expense', overflow: TextOverflow.ellipsis),
        ),
        ButtonSegment(
          value: TransactionKind.income,
          icon: const Icon(Icons.arrow_downward, size: 16),
          label: Text('Ingresos $income', overflow: TextOverflow.ellipsis),
        ),
      ],
      selected: {kind},
      onSelectionChanged: (s) => onKind(s.first),
    );
  }
}

/// Dona + lista por categoría en una sola tarjeta: cada fila tiene el
/// color de su tajada; tocarla la resalta en la dona y filtra los
/// movimientos de abajo.
class _BreakdownCard extends StatefulWidget {
  const new({
    required this.totals,
    required this.kind,
    required this.selected,
    required this.onCategory,
    required this.onOpenAnalysis,
  });

  final List<CategoryTotal> totals;
  final TransactionKind kind;
  final CategoryTotal? selected;
  final ValueChanged<String> onCategory;
  final VoidCallback onOpenAnalysis;

  @override
  State<_BreakdownCard> createState() => _BreakdownCardState();
}

class _BreakdownCardState extends State<_BreakdownCard> {
  static const _collapsedCount = 5;
  static const _dimAlpha = 0.18;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = widget.totals;
    final selected = widget.selected;
    final total = Money.sum(totals.map((t) => t.amount));
    final canCollapse = totals.length > _collapsedCount;
    final visible = _expanded || !canCollapse
        ? totals
        : [
            ...totals.take(_collapsedCount),
            // La elegida siempre se ve aunque esté más abajo.
            if (selected != null &&
                !totals.take(_collapsedCount).contains(selected))
              selected,
          ];
    final isExpense = widget.kind == TransactionKind.expense;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
        child: Column(
          children: [
            DonutChart(
              size: 170,
              values: [for (final t in totals) t.amount.cents.toDouble()],
              colors: [
                for (final t in totals)
                  CategoryStyle.color(t.category?.iconKey).withValues(
                    alpha: selected == null || t == selected ? 1 : _dimAlpha,
                  ),
              ],
              center: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selected?.category?.name ??
                          (isExpense ? 'Gastado' : 'Recibido'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Formatters.money(selected?.amount ?? total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (selected != null)
                      Text(
                        Formatters.percent(selected.share),
                        style: theme.textTheme.labelMedium,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final item in visible)
              _CategoryRow(
                item: item,
                selected: item == selected,
                dimmed: selected != null && item != selected,
                onTap: () => widget.onCategory(item.categoryId),
              ),
            Row(
              children: [
                if (canCollapse)
                  TextButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    label: Text(
                      _expanded ? 'Ver menos' : 'Ver todas (${totals.length})',
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onOpenAnalysis,
                  icon: const Icon(Icons.insights, size: 18),
                  label: Text(
                    selected == null
                        ? 'Análisis'
                        : 'Análisis de ${selected.category?.name ?? 'esto'}',
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

class _CategoryRow extends StatelessWidget {
  const new({
    required this.item,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final CategoryTotal item;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = CategoryStyle.color(item.category?.iconKey);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: dimmed ? 0.55 : 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CategoryAvatar(category: item.category, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.category?.name ?? 'Sin categoría',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: selected ? FontWeight.w700 : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.count} '
                          '${item.count == 1 ? 'movimiento' : 'movimientos'}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.money(item.amount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        Formatters.percent(item.share),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    selected ? Icons.filter_alt : Icons.filter_alt_outlined,
                    size: 18,
                    color: selected
                        ? color
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reconteo hecho al llegar el sueldo: lo registrado, lo que de verdad
/// quedó y la diferencia (verde si es poco, ámbar si hay que revisar, rojo
/// si es un desbalance grande).
class _RecountCard extends StatelessWidget {
  const new({required this.recount});

  final CycleRecount recount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = RecountStyle.color(recount.level, theme.colorScheme);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reconteo del ciclo', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LabeledValue(
                    label: 'Registrado',
                    value: Formatters.money(recount.registeredLeft),
                  ),
                ),
                Expanded(
                  child: LabeledValue(
                    label: 'Real que quedó',
                    value: Formatters.money(recount.actualLeft),
                  ),
                ),
                Expanded(
                  child: LabeledValue(
                    label: 'Diferencia',
                    value: Formatters.money(recount.difference),
                    valueColor: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RecountBadge(recount: recount),
          ],
        ),
      ),
    );
  }
}
