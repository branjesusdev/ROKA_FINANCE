import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/empty_state.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Movimientos del mes agrupados por día. Deslizar para eliminar.
class TransactionsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  YearMonth? _month;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentMonthProvider);
    final month = _month ?? current;
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };

    return Column(
      children: [
        _MonthSelector(
          month: month,
          canGoNext: month.isBefore(current),
          onChanged: (value) => setState(() => _month = value),
        ),
        Expanded(
          child: AsyncView(
            value: ref.watch(monthTransactionsProvider(month)),
            builder: (transactions) => transactions.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'No hay movimientos este mes.',
                  )
                : _TransactionList(
                    month: month,
                    transactions: transactions,
                    categories: categories,
                  ),
          ),
        ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const new({
    required this.month,
    required this.canGoNext,
    required this.onChanged,
  });

  final YearMonth month;
  final bool canGoNext;
  final ValueChanged<YearMonth> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mes anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onChanged(month.previous),
          ),
          Expanded(
            child: Text(
              Formatters.month(month),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Mes siguiente',
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoNext ? () => onChanged(month.next) : null,
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  const new({
    required this.month,
    required this.transactions,
    required this.categories,
  });

  final YearMonth month;
  final List<Transaction> transactions;
  final Map<String, Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlow = ref.watch(monthCashFlowProvider(month)).value;
    final byDay = <DateTime, List<Transaction>>{};
    for (final t in transactions) {
      byDay
          .putIfAbsent(
            DateTime(t.date.year, t.date.month, t.date.day),
            () => [],
          )
          .add(t);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        if (cashFlow != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: LabeledValue(
                    label: 'Ingresos',
                    value: Formatters.money(cashFlow.income),
                    valueColor: TransactionTile.incomeColor,
                  ),
                ),
                Expanded(
                  child: LabeledValue(
                    label: 'Gastos',
                    value: Formatters.money(cashFlow.expenses),
                  ),
                ),
                Expanded(
                  child: LabeledValue(
                    label: 'Ahorro',
                    value: Formatters.money(cashFlow.savings),
                  ),
                ),
              ],
            ),
          ),
        for (final MapEntry(key: day, value: items) in byDay.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              Formatters.longDate(day),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final t in items)
            Dismissible(
              key: ValueKey(t.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Theme.of(context).colorScheme.errorContainer,
                child: const Icon(Icons.delete_outline),
              ),
              onDismissed: (_) => _delete(context, ref, t),
              child: TransactionTile(
                transaction: t,
                category: categories[t.categoryId],
                showDate: false,
              ),
            ),
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
