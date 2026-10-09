import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Movimientos de una categoría en el ciclo, del más reciente al más
/// antiguo, cada uno con su fecha.
Future<void> showCategoryMovementsSheet(
  BuildContext context, {
  required CategoryTotal total,
  required PayCycle cycle,
  required TransactionKind kind,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    minChildSize: 0.3,
    maxChildSize: 0.95,
    builder: (context, scrollController) => CategoryMovementsSheet(
      total: total,
      cycle: cycle,
      kind: kind,
      scrollController: scrollController,
    ),
  ),
);

class CategoryMovementsSheet extends ConsumerWidget {
  const new({
    required this.total,
    required this.cycle,
    required this.kind,
    required this.scrollController,
    super.key,
  });

  final CategoryTotal total;
  final PayCycle cycle;
  final TransactionKind kind;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = total.category;
    return AsyncView(
      value: ref.watch(transactionsInRangeProvider(cycle.range)),
      builder: (transactions) {
        final items =
            transactions
                .where(
                  (t) => t.kind == kind && t.categoryId == total.categoryId,
                )
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Row(
              children: [
                CategoryAvatar(category: category, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Sin categoría',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        '${Formatters.shortDate(cycle.start)} – '
                        '${Formatters.shortDate(cycle.lastDay)} · '
                        '${items.length} '
                        '${items.length == 1 ? 'movimiento' : 'movimientos'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.money(total.amount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      Formatters.percent(total.share),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No hay movimientos en este ciclo.'),
              )
            else
              for (final t in items)
                TransactionTile(transaction: t, category: category),
          ],
        );
      },
    );
  }
}
