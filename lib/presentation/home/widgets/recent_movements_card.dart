import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Últimos movimientos (gastos e ingresos).
class RecentMovementsCard extends ConsumerWidget {
  const new({required this.onSeeAll, super.key});

  static const _maxItems = 5;

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = (ref.watch(recentTransactionsProvider).value ?? const [])
        .take(_maxItems)
        .toList();
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    return SectionCard(
      title: 'Últimos movimientos',
      trailing: items.isEmpty
          ? null
          : TextButton(onPressed: onSeeAll, child: const Text('Ver todos')),
      child: items.isEmpty
          ? Text(
              'Toca + o el micrófono para registrar un gasto en segundos.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Column(
              children: [
                for (final t in items)
                  TransactionTile(
                    transaction: t,
                    category: categories[t.categoryId],
                  ),
              ],
            ),
    );
  }
}
