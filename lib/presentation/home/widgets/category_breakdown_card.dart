import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/donut_chart.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';

/// Dona por categoría (cada una con su color) y lista con valor, % y barra.
class CategoryBreakdownCard extends StatelessWidget {
  const new({
    required this.totals,
    required this.kind,
    required this.onOpenAnalysis,
    super.key,
  });

  final List<CategoryTotal> totals;
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
        for (final item in totals) ...[
          const SizedBox(height: 8),
          _CategoryTotalTile(item: item),
        ],
      ],
    );
  }
}

class _CategoryTotalTile extends StatelessWidget {
  const new({required this.item});

  final CategoryTotal item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = CategoryStyle.color(item.category?.iconKey);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          children: [
            Row(
              children: [
                CategoryAvatar(category: item.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.category?.name ?? 'Sin categoría',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  Formatters.money(item.amount),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 52,
                  child: Text(
                    Formatters.percent(item.share),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.share.fraction.clamp(0, 1),
                minHeight: 6,
                color: color.withValues(alpha: 0.6),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
