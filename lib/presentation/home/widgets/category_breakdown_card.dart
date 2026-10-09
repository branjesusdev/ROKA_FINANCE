import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/home/widgets/category_movements_sheet.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/donut_chart.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';

/// Dona por categoría (cada una con su color) y lista compacta con valor,
/// % y barra. Al tocar una categoría se ven sus movimientos del ciclo.
class CategoryBreakdownCard extends StatelessWidget {
  const new({
    required this.totals,
    required this.cycle,
    required this.kind,
    required this.onOpenAnalysis,
    super.key,
  });

  final List<CategoryTotal> totals;
  final PayCycle cycle;
  final TransactionKind kind;
  final VoidCallback onOpenAnalysis;

  bool get _isExpense => kind == TransactionKind.expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = Money.sum(totals.map((t) => t.amount));
    return Column(
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                DonutChart(
                  size: 200,
                  strokeWidth: 26,
                  values: [for (final t in totals) t.amount.cents.toDouble()],
                  colors: [
                    for (final t in totals)
                      CategoryStyle.color(t.category?.iconKey),
                  ],
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpense ? 'Gastado' : 'Recibido',
                        style: theme.textTheme.bodySmall,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            Formatters.money(total),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (totals.isEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _isExpense
                        ? 'Aún no hay gastos en este ciclo.'
                        : 'Aún no hay ingresos en este ciclo.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ] else if (_isExpense)
                  TextButton(
                    onPressed: onOpenAnalysis,
                    child: const Text('Ver análisis'),
                  ),
              ],
            ),
          ),
        ),
        if (totals.isNotEmpty) ...[
          const SizedBox(height: 8),
          _CategoryList(totals: totals, cycle: cycle, kind: kind),
        ],
      ],
    );
  }
}

/// Lista compacta en una sola tarjeta. Muestra las primeras
/// [_collapsedCount] y el resto al tocar "Ver todas".
class _CategoryList extends StatefulWidget {
  const new({required this.totals, required this.cycle, required this.kind});

  final List<CategoryTotal> totals;
  final PayCycle cycle;
  final TransactionKind kind;

  @override
  State<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<_CategoryList> {
  static const _collapsedCount = 5;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final totals = widget.totals;
    final canCollapse = totals.length > _collapsedCount;
    final visible = _expanded || !canCollapse
        ? totals
        : totals.take(_collapsedCount);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final item in visible)
            _CategoryTotalTile(
              item: item,
              onTap: () => showCategoryMovementsSheet(
                context,
                total: item,
                cycle: widget.cycle,
                kind: widget.kind,
              ),
            ),
          if (canCollapse)
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(
                _expanded ? 'Ver menos' : 'Ver todas (${totals.length})',
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTotalTile extends StatelessWidget {
  const new({required this.item, required this.onTap});

  final CategoryTotal item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = CategoryStyle.color(item.category?.iconKey);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            CategoryAvatar(category: item.category, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.category?.name ?? 'Sin categoría',
                          style: theme.textTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Formatters.money(item.amount),
                        style: theme.textTheme.bodyMedium,
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          Formatters.percent(item.share),
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.share.fraction.clamp(0, 1),
                      minHeight: 4,
                      color: color.withValues(alpha: 0.6),
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
