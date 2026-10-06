import 'package:finance_app/application/insights/financial_health.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/insights/insight.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/traffic_light_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Salud financiera: métricas individuales + observaciones descriptivas.
class InsightsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis')),
      body: AsyncView(
        value: ref.watch(financialHealthProvider),
        builder: (health) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _ObservationsCard(health: health, categories: categories),
            const SizedBox(height: 12),
            _IndicatorsCard(health: health),
            const SizedBox(height: 12),
            _BreakdownCard(health: health, categories: categories),
            const SizedBox(height: 16),
            Text(
              'Información descriptiva calculada con los datos que registras. '
              'No es asesoría financiera.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservationsCard extends StatelessWidget {
  const new({required this.health, required this.categories});

  final FinancialHealth health;
  final Map<String, Category> categories;

  @override
  Widget build(BuildContext context) {
    final insights = health.insights;
    return SectionCard(
      title: '¿Dónde se va mi dinero?',
      child: insights.isEmpty
          ? const Text(
              'Aún no hay suficientes datos este mes para detectar patrones.',
            )
          : Column(
              children: [
                for (final insight in insights)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_icon(insight)),
                    title: Text(_describe(insight)),
                  ),
              ],
            ),
    );
  }

  String _name(String id) => categories[id]?.name ?? 'Otra categoría';

  String _describe(Insight insight) => switch (insight) {
    CategoryShareInsight(:final categoryId, :final share, :final amount) =>
      '${_name(categoryId)} representa el ${Formatters.percent(share)} de '
          'tus gastos (${Formatters.money(amount)}).',
    CategoryVariationInsight(:final categoryId, :final change)
        when change.isNegative =>
      '${_name(categoryId)} bajó ${Formatters.percent(change.abs)} respecto '
          'al mes anterior.',
    CategoryVariationInsight(:final categoryId, :final change) =>
      '${_name(categoryId)} aumentó ${Formatters.percent(change)} respecto '
          'al mes anterior.',
    TotalSpendingVariationInsight(:final change) when change.isNegative =>
      'Tus gastos bajaron ${Formatters.percent(change.abs)} frente al mes '
          'anterior.',
    TotalSpendingVariationInsight(:final change) =>
      'Tus gastos subieron ${Formatters.percent(change)} frente al mes '
          'anterior.',
    SmallExpensesInsight(:final count, :final total, :final threshold) =>
      'Has realizado $count compras pequeñas (hasta '
          '${Formatters.money(threshold)}) que suman '
          '${Formatters.money(total)}.',
    BudgetUsageInsight(:final usage, :final light) =>
      light == TrafficLight.critical
          ? 'Superaste tu presupuesto: vas en el ${Formatters.percent(usage)}.'
          : 'Estás utilizando el ${Formatters.percent(usage)} de tu '
                'presupuesto.',
  };

  IconData _icon(Insight insight) => switch (insight) {
    CategoryShareInsight() => Icons.pie_chart_outline,
    CategoryVariationInsight(:final change) ||
    TotalSpendingVariationInsight(
      :final change,
    ) => change.isNegative ? Icons.trending_down : Icons.trending_up,
    SmallExpensesInsight() => Icons.local_cafe_outlined,
    BudgetUsageInsight(:final light) => TrafficLightStyle.icon(light),
  };
}

class _IndicatorsCard extends StatelessWidget {
  const new({required this.health});

  final FinancialHealth health;

  @override
  Widget build(BuildContext context) {
    final cashFlow = health.cashFlow;
    final netWorth = health.netWorth;
    final budgetUsage = health.budget.hasBudget
        ? health.budget.total.usage
        : null;

    return SectionCard(
      title: 'Indicadores del mes',
      child: Column(
        children: [
          _Indicator(
            label: 'Tasa de ahorro',
            value: _percentOrDash(cashFlow.savingsRate),
            explanation: cashFlow.savingsRate == null
                ? 'Registra tus ingresos para calcularla.'
                : r'De cada $100 que ganas, te quedan '
                      '\$${cashFlow.savingsRate!.value.round()}.',
          ),
          _Indicator(
            label: 'Gastos sobre ingresos',
            value: _percentOrDash(cashFlow.expenseRatio),
            explanation: 'Qué parte de lo que ganas se va en gastos.',
          ),
          _Indicator(
            label: 'Deuda sobre activos',
            value: _percentOrDash(netWorth.debtRatio),
            explanation: 'Cuánto debes comparado con lo que tienes.',
          ),
          _Indicator(
            label: 'Patrimonio neto',
            value: Formatters.money(netWorth.total),
            explanation: 'Lo que tienes menos lo que debes.',
          ),
          _Indicator(
            label: 'Presupuesto utilizado',
            value: _percentOrDash(budgetUsage),
            explanation: budgetUsage == null
                ? 'Define límites en la pestaña Presupuesto.'
                : 'Del total que planeaste gastar este mes.',
          ),
          _Indicator(
            label: 'Fondo de emergencia',
            value: _percentOrDash(health.emergencyProgress),
            explanation: health.emergencyProgress == null
                ? 'Configúralo en la pestaña Metas.'
                : 'Avance hacia tu colchón para imprevistos.',
          ),
          _Indicator(
            label: 'Progreso de metas',
            value: _percentOrDash(health.goalsProgress),
            explanation: 'Ahorrado frente al total de tus metas.',
          ),
          _Indicator(
            label: 'Gasto vs mes anterior',
            value: health.spendingChange == null
                ? '-'
                : '${health.spendingChange!.isNegative ? '' : '+'}'
                      '${Formatters.percent(health.spendingChange!)}',
            explanation: 'Cambio de tus gastos frente al mes pasado.',
          ),
        ],
      ),
    );
  }

  static String _percentOrDash(Percentage? value) =>
      value == null ? '-' : Formatters.percent(value);
}

class _Indicator extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.explanation,
  });

  final String label;
  final String value;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall),
                Text(explanation, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const new({required this.health, required this.categories});

  final FinancialHealth health;
  final Map<String, Category> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Gasto por categoría',
      child: health.breakdown.isEmpty
          ? const Text('Sin gastos este mes.')
          : Column(
              children: [
                for (final item in health.breakdown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CategoryAvatar(
                              category: categories[item.categoryId],
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                categories[item.categoryId]?.name ??
                                    'Sin categoría',
                              ),
                            ),
                            Text(
                              '${Formatters.money(item.amount)} · '
                              '${Formatters.percent(item.share)}',
                              style: theme.textTheme.labelLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: item.share.fraction.clamp(0, 1).toDouble(),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        Text(
                          '${item.count} '
                          '${item.count == 1 ? 'movimiento' : 'movimientos'}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
