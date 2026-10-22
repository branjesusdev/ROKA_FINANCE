import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/fixed/fixed_cycle_status.dart';
import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/fixed/fixed_coverage.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/fixed/bill_actions.dart';
import 'package:finance_app/presentation/fixed/fixed_movement_form.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/donut_chart.dart';
import 'package:finance_app/presentation/shared/empty_state.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/motion.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gastos e ingresos que se repiten cada mes. Se registran solos el día
/// indicado dentro de cada ciclo.
///
/// Por color: lo que falta pagar (ámbar, rojo si no alcanza la plata) va
/// arriba; lo ya pagado este ciclo, en verde.
class FixedMovementsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final statuses = {
      for (final s
          in ref.watch(fixedCycleStatusProvider).value ??
              const <FixedCycleStatus>[])
        s.movement.id: s,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Fijos del mes')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nuevo fijo',
        onPressed: () =>
            showFormSheet<void>(context, const FixedMovementFormSheet()),
        child: const Icon(Icons.add),
      ),
      body: AsyncView(
        value: ref.watch(fixedMovementsProvider),
        builder: (movements) {
          if (movements.isEmpty) {
            return const EmptyState(
              icon: Icons.event_repeat,
              message:
                  'Agrega arriendo, colegio, cuota alimentaria, entrenos, '
                  'crédito o tu sueldo. Se registran solos cada mes.',
            );
          }
          // El orden ya viene de FixedCycleStatusBuilder; los fijos recién
          // creados (aún sin estado) van al final.
          final ordered = [
            for (final s in statuses.values)
              if (movements.any((m) => m.id == s.movement.id)) s,
            for (final m in movements)
              if (!statuses.containsKey(m.id))
                FixedCycleStatus(
                  movement: m,
                  state: m.isActive
                      ? FixedCycleState.notThisCycle
                      : FixedCycleState.paused,
                ),
          ];
          final expenses = ordered.where((s) => s.movement.isExpense);
          final pending = expenses.where((s) => s.isPending).toList();
          final paid = expenses.where((s) => s.isDone).toList();
          final rest = expenses
              .where((s) => !s.isPending && !s.isDone)
              .toList();
          final incomes = ordered.where((s) => !s.movement.isExpense).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _FixedHeader(
                overview: const FixedCycleOverviewBuilder().build(
                  statuses: ordered,
                  categories: categories,
                ),
              ),
              const SizedBox(height: 12),
              if (pending.isNotEmpty) ...[
                _FixedGroup(
                  title: 'Por pagar este ciclo',
                  statuses: pending,
                  categories: categories,
                ),
                const SizedBox(height: 12),
              ],
              if (paid.isNotEmpty) ...[
                _FixedGroup(
                  title: 'Ya pagados este ciclo',
                  statuses: paid,
                  categories: categories,
                ),
                const SizedBox(height: 12),
              ],
              if (incomes.isNotEmpty) ...[
                _FixedGroup(
                  title: 'Ingresos fijos',
                  statuses: incomes,
                  categories: categories,
                ),
                const SizedBox(height: 12),
              ],
              if (rest.isNotEmpty)
                _FixedGroup(
                  title: 'Pausados o sin cobro este ciclo',
                  statuses: rest,
                  categories: categories,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Conteo completo de los fijos del ciclo: total, cuánto va pagado (barra),
/// vencidos, ingresos fijos y en qué categorías se va más (dona + lista).
class _FixedHeader extends StatelessWidget {
  const new({required this.overview});

  final FixedCycleOverview overview;

  static const _donutSize = 132.0;
  static const _donutStroke = 18.0;
  static const _barHeight = 10.0;
  static const _pendingTrackAlpha = 0.35;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ok = StatusColors.okOf(scheme);
    final warning = StatusColors.warningOf(scheme);
    final o = overview;
    final paidShare = o.paidShare;
    final categories = o.byCategory;
    final overdueS = o.overdueCount == 1 ? '' : 's';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos fijos de este ciclo',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            AnimatedMoneyText(
              amount: o.expenseTotal,
              format: Formatters.money,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              [
                '${o.expenseCount} ${o.expenseCount == 1 ? 'fijo' : 'fijos'}',
                if (paidShare != null)
                  '${Formatters.percent(paidShare)} pagado',
                if (o.pausedCount > 0) '${o.pausedCount} pausados',
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (o.expenseTotal.isPositive) ...[
              const SizedBox(height: 12),
              Semantics(
                label:
                    'Pagado ${Formatters.money(o.paid)} de '
                    '${Formatters.money(o.expenseTotal)}',
                excludeSemantics: true,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: o.paid.cents / o.expenseTotal.cents,
                  ),
                  duration: Motion.enabled(context)
                      ? Motion.slow
                      : Duration.zero,
                  curve: Motion.emphasized,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: _barHeight,
                    color: ok,
                    backgroundColor: warning.withValues(
                      alpha: _pendingTrackAlpha,
                    ),
                    borderRadius: BorderRadius.circular(_barHeight / 2),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LabeledValue(
                    label: 'Ya pagado (${o.paidCount})',
                    value: Formatters.money(o.paid),
                    valueColor: ok,
                  ),
                ),
                Expanded(
                  child: LabeledValue(
                    label: 'Por pagar (${o.pendingCount})',
                    value: Formatters.money(o.pending),
                    valueColor: warning,
                  ),
                ),
              ],
            ),
            if (o.overdueCount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: scheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${o.overdueCount} vencido$overdueS por '
                      '${Formatters.money(o.overdue)}: confírmalo$overdueS '
                      'abajo.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (o.incomeTotal.isPositive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LabeledValue(
                      label: 'Ingresos fijos',
                      value: Formatters.money(o.incomeTotal),
                    ),
                  ),
                  Expanded(
                    child: LabeledValue(
                      label: o.net.isNegative
                          ? 'Fijos pasan tus ingresos fijos'
                          : 'Queda después de fijos',
                      value: Formatters.money(o.net),
                      valueColor: o.net.isNegative ? scheme.error : null,
                    ),
                  ),
                ],
              ),
            ],
            if (categories.isNotEmpty) ...[
              const Divider(height: 28),
              Text('Dónde se va más', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DonutChart(
                    size: _donutSize,
                    strokeWidth: _donutStroke,
                    values: [
                      for (final c in categories) c.amount.cents.toDouble(),
                    ],
                    colors: [
                      for (final c in categories)
                        CategoryStyle.color(c.category?.iconKey),
                    ],
                    center: Text(
                      Formatters.percent(categories.first.share),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        for (final c in categories) _CategoryShare(total: c),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila de la leyenda: icono y color de la categoría, monto y porcentaje.
class _CategoryShare extends StatelessWidget {
  const new({required this.total});

  final CategoryTotal total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconKey = total.category?.iconKey;
    final color = CategoryStyle.color(iconKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(CategoryStyle.icon(iconKey), size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total.category?.name ?? 'Sin categoría',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${Formatters.money(total.amount)} · '
                  '${Formatters.percent(total.share)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedGroup extends StatelessWidget {
  const new({
    required this.title,
    required this.statuses,
    required this.categories,
  });

  final String title;
  final List<FixedCycleStatus> statuses;
  final Map<String, Category> categories;

  @override
  Widget build(BuildContext context) {
    final active = statuses.where((s) => s.movement.isActive);
    final total = Money.sum(active.map((s) => s.movement.amount));
    return SectionCard(
      title: title,
      trailing: Text(
        Formatters.money(total),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      child: Column(
        children: [
          for (final status in statuses)
            _FixedTile(
              status: status,
              category: categories[status.movement.categoryId],
            ),
        ],
      ),
    );
  }
}

/// Color, icono y texto del estado (nunca solo color).
abstract final class _StateStyle {
  static Color color(FixedCycleStatus s, ColorScheme scheme) =>
      switch (s.state) {
        FixedCycleState.paid ||
        FixedCycleState.received => StatusColors.okOf(scheme),
        FixedCycleState.upcoming when s.coverage == ObligationState.uncovered =>
          scheme.error,
        FixedCycleState.upcoming ||
        FixedCycleState.overdue => StatusColors.warningOf(scheme),
        FixedCycleState.paused ||
        FixedCycleState.notThisCycle => scheme.outline,
      };

  static IconData icon(FixedCycleStatus s) => switch (s.state) {
    FixedCycleState.paid || FixedCycleState.received => Icons.check_circle,
    FixedCycleState.overdue => Icons.schedule,
    FixedCycleState.upcoming => Icons.event_outlined,
    FixedCycleState.paused => Icons.pause_circle_outline,
    FixedCycleState.notThisCycle => Icons.event_busy_outlined,
  };

  static String label(FixedCycleStatus s, DateTime now) {
    final date = s.date;
    final when = date == null ? '' : ' ${Formatters.shortDate(date)}';
    return switch (s.state) {
      FixedCycleState.paid => 'Pagado$when',
      FixedCycleState.received => 'Recibido$when',
      FixedCycleState.overdue when date != null => billStateLabel(
        ScheduledFixed(movement: s.movement, date: date),
        now,
      ),
      FixedCycleState.overdue => 'Falta el valor',
      FixedCycleState.upcoming when !s.movement.isExpense => 'Llega$when',
      FixedCycleState.upcoming => 'Por pagar$when',
      FixedCycleState.paused => 'Pausado',
      FixedCycleState.notThisCycle => 'No le toca este ciclo',
    };
  }
}

class _FixedTile extends ConsumerWidget {
  const new({required this.status, required this.category});

  final FixedCycleStatus status;
  final Category? category;

  static const _stripeWidth = 4.0;
  static const _stripeHeight = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider).now();
    final date = status.date;
    final bill = status.state == FixedCycleState.overdue && date != null
        ? ScheduledFixed(movement: status.movement, date: date)
        : null;
    final movement = status.movement;
    final sign = movement.kind == TransactionKind.expense ? '-' : '+';
    final color = _StateStyle.color(status, theme.colorScheme);
    final coverage = status.coverage;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showFormSheet<void>(
        context,
        FixedMovementFormSheet(movement: movement),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: _stripeWidth,
              height: _stripeHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(_stripeWidth / 2),
              ),
            ),
            const SizedBox(width: 10),
            CategoryAvatar(category: category, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movement.name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    [
                      'Cada día ${movement.dayOfMonth}',
                      if (category != null) category!.name,
                      if (movement.isVariable) 'valor variable',
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      StatusChip(
                        icon: _StateStyle.icon(status),
                        label: _StateStyle.label(status, now),
                        color: color,
                      ),
                      if (coverage != null &&
                          status.state == FixedCycleState.upcoming)
                        StatusChip(
                          icon: ObligationStyle.icon(coverage),
                          label: ObligationStyle.label(coverage),
                          color: ObligationStyle.color(
                            coverage,
                            theme.colorScheme,
                          ),
                        ),
                    ],
                  ),
                  if (bill != null) ...[
                    const SizedBox(height: 6),
                    BillActions(bill: bill),
                  ],
                  if (status.state == FixedCycleState.paid &&
                      date != null &&
                      movement.debtId == null &&
                      !movement.autoDebit)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () =>
                          _markUnpaid(context, ref, movement, date),
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Aún no lo he pagado'),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$sign${Formatters.money(movement.amount)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: status.isDone ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deshace el pago registrado: vuelve a "por confirmar" con avisos.
Future<void> _markUnpaid(
  BuildContext context,
  WidgetRef ref,
  FixedMovement movement,
  DateTime paidOn,
) async {
  final result = await ref
      .read(markFixedUnpaidProvider)
      .call(movement: movement, paidOn: paidOn);
  if (!context.mounted) return;
  showResult(context, result, success: '${movement.name}: queda por confirmar');
}

/// Borra un fijo previa confirmación. Los movimientos ya registrados se
/// conservan. Devuelve `true` si se eliminó.
Future<bool> deleteFixedMovement(
  BuildContext context,
  WidgetRef ref,
  FixedMovement movement,
) async {
  final delete = ref.read(deleteFixedMovementProvider);
  if (!await confirmDelete(context, 'este fijo')) return false;
  final result = await delete(movement.id);
  if (!context.mounted) return false;
  return showResult(context, result, success: 'Fijo eliminado');
}
