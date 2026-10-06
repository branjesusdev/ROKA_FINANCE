import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/budgets/budget_evaluator.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/traffic_light_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presupuesto mensual por categoría: presupuesto, gastado, disponible, %.
class BudgetScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final categories = (ref.watch(categoriesProvider).value ?? const [])
        .where((c) => c.kind == CategoryKind.expense && !c.isArchived)
        .toList();
    final lines = ref.watch(budgetLinesProvider(month)).value ?? const [];
    final spending = ref.watch(monthSpendingProvider(month)).value ?? const {};

    return AsyncView(
      value: ref.watch(monthBudgetProvider(month)),
      builder: (budget) {
        final statusById = {
          for (final c in budget.categories) c.categoryId: c.status,
        };
        final lineById = {for (final l in lines) l.categoryId: l};
        final budgeted = categories.where(lineById.containsKey).toList()
          ..sort(
            (a, b) => (statusById[b.id]?.usage?.basisPoints ?? 0).compareTo(
              statusById[a.id]?.usage?.basisPoints ?? 0,
            ),
          );
        final unbudgeted = categories
            .where((c) => !lineById.containsKey(c.id))
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _TotalCard(month: month, budget: budget),
            const SizedBox(height: 12),
            if (budgeted.isNotEmpty)
              SectionCard(
                title: 'Con límite',
                child: Column(
                  children: [
                    for (final category in budgeted)
                      _BudgetedTile(
                        category: category,
                        status: statusById[category.id]!,
                        onTap: () => _editLimit(
                          context,
                          month,
                          category,
                          lineById[category.id],
                        ),
                      ),
                  ],
                ),
              ),
            if (budgeted.isNotEmpty) const SizedBox(height: 12),
            SectionCard(
              title: 'Sin límite',
              child: Column(
                children: [
                  for (final category in unbudgeted)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CategoryAvatar(category: category, size: 36),
                      title: Text(category.name),
                      subtitle: Text('Gastado ${_spent(spending, category)}'),
                      trailing: TextButton(
                        onPressed: () =>
                            _editLimit(context, month, category, null),
                        child: const Text('Definir'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editLimit(
    BuildContext context,
    YearMonth month,
    Category category,
    BudgetLine? line,
  ) => showFormSheet<void>(
    context,
    _BudgetLimitSheet(month: month, category: category, line: line),
  );
}

String _spent(Map<String, Money> spending, Category category) =>
    Formatters.money(spending[category.id] ?? Money.zero);

class _TotalCard extends ConsumerWidget {
  const new({required this.month, required this.budget});

  final YearMonth month;
  final MonthBudgetStatus budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = budget.total;
    final usage = total.usage;

    return SectionCard(
      title: 'Presupuesto de ${Formatters.month(month)}',
      trailing: budget.hasBudget ? TrafficLightBadge(light: total.light) : null,
      child: !budget.hasBudget
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Define cuánto quieres gastar como máximo en cada categoría. '
                  'Toca "Definir" en una categoría para empezar.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await ref
                        .read(copyPreviousMonthBudgetProvider)
                        .call(month);
                    if (!context.mounted) return;
                    showResult(
                      context,
                      result,
                      success: result.fold(
                        onOk: (count) => count == 0
                            ? 'El mes anterior no tenía presupuesto.'
                            : 'Se copiaron $count límites.',
                        onErr: (_) => null,
                      ),
                    );
                  },
                  icon: const Icon(Icons.content_copy),
                  label: const Text('Copiar del mes anterior'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LabeledValue(
                        label: 'Presupuesto',
                        value: Formatters.money(total.limit),
                      ),
                    ),
                    Expanded(
                      child: LabeledValue(
                        label: 'Gastado',
                        value: Formatters.money(total.spent),
                      ),
                    ),
                    Expanded(
                      child: LabeledValue(
                        label: total.isOverBudget ? 'Excedido' : 'Disponible',
                        value: Formatters.money(total.available.abs),
                        valueColor: total.isOverBudget
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ),
                  ],
                ),
                if (usage != null) ...[
                  const SizedBox(height: 12),
                  _UsageBar(status: total),
                ],
                if (budget.overBudget.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    budget.overBudget.length == 1
                        ? '1 categoría superó su límite.'
                        : '${budget.overBudget.length} categorías superaron '
                              'su límite.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _BudgetedTile extends StatelessWidget {
  const new({
    required this.category,
    required this.status,
    required this.onTap,
  });

  final Category category;
  final BudgetStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryAvatar(category: category, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(category.name, style: theme.textTheme.titleSmall),
                ),
                Icon(
                  TrafficLightStyle.icon(status.light),
                  size: 18,
                  color: TrafficLightStyle.color(
                    status.light,
                    theme.colorScheme,
                  ),
                  semanticLabel: TrafficLightStyle.label(status.light),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _UsageBar(status: status),
          ],
        ),
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  const new({required this.status});

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usage = status.usage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: usage?.fraction.clamp(0, 1).toDouble() ?? 1,
          color: TrafficLightStyle.color(status.light, theme.colorScheme),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          semanticsLabel: 'Uso del presupuesto',
          semanticsValue: usage == null ? null : Formatters.percent(usage),
        ),
        const SizedBox(height: 4),
        Text(
          '${usage == null ? '' : '${Formatters.percent(usage)} · '}'
          '${Formatters.money(status.spent)} de '
          '${Formatters.money(status.limit)}'
          ' · ${status.isOverBudget ? 'excedido' : 'quedan'} '
          '${Formatters.money(status.available.abs)}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _BudgetLimitSheet extends ConsumerStatefulWidget {
  const new({required this.month, required this.category, required this.line});

  final YearMonth month;
  final Category category;
  final BudgetLine? line;

  @override
  ConsumerState<_BudgetLimitSheet> createState() => _BudgetLimitSheetState();
}

class _BudgetLimitSheetState extends ConsumerState<_BudgetLimitSheet> {
  late final _limit = TextEditingController(
    text: MoneyField.initial(widget.line?.limit),
  );

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return FormSheet(
      title: 'Límite para ${widget.category.name}',
      onSave: _save,
      extraActions: [
        if (line != null)
          TextButton(
            onPressed: () async {
              final result = await ref.read(removeBudgetLimitProvider)(line.id);
              if (!context.mounted) return;
              if (showResult(context, result, success: 'Límite eliminado')) {
                Navigator.pop(context);
              }
            },
            child: const Text('Quitar límite'),
          ),
      ],
      children: [
        MoneyField(
          controller: _limit,
          label: 'Máximo a gastar este mes',
          autofocus: true,
        ),
      ],
    );
  }

  Future<void> _save() async {
    final result = await ref
        .read(setBudgetLimitProvider)
        .call(
          period: widget.month,
          categoryId: widget.category.id,
          limit: MoneyField.read(_limit) ?? Money.zero,
        );
    if (!mounted) return;
    if (showResult(context, result, success: 'Límite guardado')) {
      Navigator.pop(context);
    }
  }
}
