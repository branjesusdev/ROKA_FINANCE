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
import 'package:finance_app/presentation/shared/empty_state.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showFormSheet<void>(context, const FixedMovementFormSheet()),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo fijo'),
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
              _CycleTotals(pending: pending, paid: paid),
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

/// Cuánto falta y cuánto ya salió de los gastos fijos del ciclo.
class _CycleTotals extends StatelessWidget {
  const new({required this.pending, required this.paid});

  final List<FixedCycleStatus> pending;
  final List<FixedCycleStatus> paid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Money total(List<FixedCycleStatus> list) =>
        Money.sum(list.map((s) => s.movement.amount));
    return SectionCard(
      title: 'Gastos fijos de este ciclo',
      child: Row(
        children: [
          Expanded(
            child: LabeledValue(
              label: 'Por pagar (${pending.length})',
              value: Formatters.money(total(pending)),
              valueColor: StatusColors.warningOf(scheme),
            ),
          ),
          Expanded(
            child: LabeledValue(
              label: 'Ya pagado (${paid.length})',
              value: Formatters.money(total(paid)),
              valueColor: StatusColors.okOf(scheme),
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
