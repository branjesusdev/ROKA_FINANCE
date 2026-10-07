import 'package:finance_app/application/dashboard/daily_spending.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/days/daily_bar_chart.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Mis días": barras de gasto por día del ciclo, detalle del día elegido y
/// el histórico de ciclos (sobrante o déficit) para mejorar el siguiente.
class DailySpendingScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DailySpendingScreen> createState() =>
      _DailySpendingScreenState();
}

class _DailySpendingScreenState extends ConsumerState<DailySpendingScreen> {
  DaySpending? _selected;

  @override
  Widget build(BuildContext context) {
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Mis días')),
      body: AsyncView(
        value: ref.watch(dailySpendingProvider),
        builder: (series) {
          final selected =
              _selected ?? (series.days.isEmpty ? null : series.days.last);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _ChartCard(
                series: series,
                selected: selected,
                onSelected: (day) => setState(() => _selected = day),
              ),
              if (selected != null) ...[
                const SizedBox(height: 12),
                _DayCard(day: selected, categories: categories),
              ],
              const SizedBox(height: 12),
              const _HistoryCard(),
            ],
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const new({
    required this.series,
    required this.selected,
    required this.onSelected,
  });

  final DailySpendingSeries series;
  final DaySpending? selected;
  final ValueChanged<DaySpending> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cap = series.cap;
    return SectionCard(
      title: 'Gasto por día de este ciclo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DailyBarChart(
            series: series,
            selected: selected?.date,
            onSelected: onSelected,
          ),
          const SizedBox(height: 8),
          const DailyChartLegend(),
          const SizedBox(height: 12),
          Text(
            'Promedio del día a día: '
            '${Formatters.money(series.averageDayToDay)}'
            '${cap == null ? '' : ' · tope de hoy ${Formatters.money(cap)}'}',
            style: theme.textTheme.bodyMedium,
          ),
          if (cap != null) ...[
            const SizedBox(height: 4),
            Text(
              series.daysOverCap == 0
                  ? 'Ningún día por encima del tope. ¡Así se construye!'
                  : '${series.daysOverCap} '
                        '${series.daysOverCap == 1 ? 'día' : 'días'} por '
                        'encima del tope.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'El cuadre con tu dinero real no aparece en las barras.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const new({required this.day, required this.categories});

  final DaySpending day;
  final Map<String, Category> categories;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: Formatters.longDate(day.date),
      trailing: Text(
        Formatters.money(day.total),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      child: day.transactions.isEmpty
          ? const Text('Sin gastos este día.')
          : Column(
              children: [
                for (final t in day.transactions)
                  TransactionTile(
                    transaction: t,
                    category: categories[t.categoryId],
                    showDate: false,
                  ),
              ],
            ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const new();

  static String _untracked(Money amount) =>
      amount.isPositive ? ' · sin registrar ${Formatters.money(amount)}' : '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final records = ref.watch(cycleHistoryProvider).value ?? const [];
    return SectionCard(
      title: 'Histórico de ciclos',
      child: records.isEmpty
          ? const Text('Aún no hay ciclos registrados.')
          : Column(
              children: [
                for (final (i, r) in records.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      r.result.isNegative
                          ? Icons.trending_down
                          : Icons.trending_up,
                      color: r.result.isNegative
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                    title: Text(
                      '${i == 0 ? 'Actual · ' : ''}'
                      '${Formatters.shortDate(r.cycle.start)} – '
                      '${Formatters.shortDate(r.cycle.lastDay)}',
                    ),
                    subtitle: Text(
                      'Ingresos ${Formatters.money(r.income)} · salió '
                      '${Formatters.money(r.spent)}'
                      '${_untracked(r.untracked)}',
                    ),
                    trailing: Text(
                      '${r.result.isNegative ? 'Déficit' : 'Sobró'}\n'
                      '${Formatters.money(r.result.abs)}',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: r.result.isNegative
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
