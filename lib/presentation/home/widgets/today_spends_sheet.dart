import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gastos de hoy separados en lo que cuenta en el tope del día y lo que no
/// (con el porqué), para entender el "llevas" del Inicio.
Future<void> showTodaySpendsSheet(
  BuildContext context, {
  required CycleSummary summary,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _TodaySpendsSheet(spends: summary.todaySpends),
);

class _TodaySpendsSheet extends ConsumerWidget {
  const new({required this.spends});

  final List<TodaySpend> spends;

  static const _maxHeightFactor = 0.85;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final inCap = spends.where((s) => s.countsInCap).toList();
    final outside = spends.where((s) => !s.countsInCap).toList();

    Widget section(String title, String note, List<TodaySpend> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title · ${Formatters.money(_total(items))}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(note, style: theme.textTheme.bodySmall),
        for (final s in items)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TransactionTile(
                transaction: s.transaction,
                category: categories[s.transaction.categoryId],
                showDate: false,
              ),
              if (!s.countsInCap)
                Padding(
                  padding: const EdgeInsets.only(left: 56, bottom: 4),
                  child: Text(
                    _reason(s, categories[s.transaction.categoryId]),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFactor,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('Tus gastos de hoy', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Gastaste ${Formatters.money(_total(spends))} hoy. Solo el día a '
            'día (ropa, comida afuera, transporte, antojos) baja el tope. Lo '
            'demás ya lo tenías apartado del sueldo: fijos, cuotas, mercado, '
            'salud, servicios, hijos y ahorro.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          section(
            'Cuenta en el tope',
            inCap.isEmpty
                ? 'Nada del día a día todavía.'
                : 'Almuerzos, transporte, antojos y demás gasto variable.',
            inCap,
          ),
          if (outside.isNotEmpty)
            section(
              'No cuenta en el tope',
              'Ya se descontó de lo libre: no te quita del tope de hoy.',
              outside,
            ),
        ],
      ),
    );
  }

  static Money _total(List<TodaySpend> items) =>
      Money.sum(items.map((s) => s.transaction.amount));

  static String _reason(TodaySpend spend, Category? category) {
    final name = category?.name ?? 'Esta categoría';
    return switch (spend.kind) {
      TodaySpendKind.linked =>
        'Fijo, cuota de crédito o pago del año: ya estaba descontado.',
      TodaySpendKind.monthly
          when spend.transaction.categoryId ==
              CycleSummaryBuilder.familyCategoryId =>
        '$name sale del colchón mensual para los niños, no del tope.',
      TodaySpendKind.monthly =>
        '$name se planea por mes: sale de su presupuesto, no del tope.',
      TodaySpendKind.saving => 'Ahorro o inversión: no es gasto.',
      TodaySpendKind.dayToDay => 'Día a día',
    };
  }
}
