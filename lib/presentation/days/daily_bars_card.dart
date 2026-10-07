import 'package:finance_app/presentation/days/daily_bar_chart.dart';
import 'package:finance_app/presentation/days/daily_spending_screen.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Barras de gasto por día en el Home; abre "Mis días" con el detalle.
class DailyBarsCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(dailySpendingProvider).value;
    if (series == null || series.days.isEmpty) return const SizedBox.shrink();
    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DailySpendingScreen()),
    );
    return SectionCard(
      title: 'Gasto por día',
      trailing: TextButton(onPressed: open, child: const Text('Ver detalle')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DailyBarChart(series: series, height: 140, onSelected: (_) => open()),
          const SizedBox(height: 8),
          const DailyChartLegend(),
        ],
      ),
    );
  }
}
