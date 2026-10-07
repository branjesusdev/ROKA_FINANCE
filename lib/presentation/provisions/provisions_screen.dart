import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/provisions/provision_planner.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/provisions/provision_forms.dart';
import 'package:finance_app/presentation/provisions/provision_templates.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/traffic_light_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pagos que no son mensuales (gimnasio trimestral, SOAT, tecnomecánica,
/// colegio…): cuánto apartar en cada ciclo y cómo vas.
class ProvisionsScreen extends ConsumerWidget {
  const new({super.key});

  static const _spacing = SizedBox(height: 12);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final provisions = ref.watch(provisionsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos del año')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showFormSheet<void>(context, const ProvisionFormSheet()),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo pago'),
      ),
      body: AsyncView(
        value: ref.watch(cycleSummaryProvider),
        builder: (summary) {
          final plan = summary.provisionPlan;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (!plan.isEmpty) ...[
                _PlanSummaryCard(plan: plan),
                _spacing,
                _SalaryOrderCard(summary: summary),
                _spacing,
                for (final status in plan.statuses) ...[
                  _ProvisionCard(
                    status: status,
                    category: categories[status.provision.categoryId],
                  ),
                  _spacing,
                ],
              ] else ...[
                const _IntroCard(),
                _spacing,
              ],
              for (final paused in provisions.where((p) => !p.isActive)) ...[
                _PausedTile(provision: paused),
                _spacing,
              ],
              _TemplatesCard(existing: {for (final p in provisions) p.name}),
            ],
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: '¿Cómo funciona?',
      child: Text(
        'Agrega lo que pagas cada cierto tiempo: gimnasio trimestral, SOAT, '
        'tecnomecánica, mantenimiento, colegio… Te decimos cuánto apartar '
        'en cada sueldo y cada día para que llegue la fecha con la plata '
        'lista. Si te atrasas, lo verás en rojo.',
      ),
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const new({required this.plan});

  final ProvisionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final today = plan.todaySetAside;
    return SectionCard(
      title: 'Este ciclo',
      trailing: TrafficLightBadge(light: plan.light),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            today == null
                ? 'Ya apartaste lo de este ciclo'
                : 'Aparta hoy ${Formatters.money(today)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Faltan ${Formatters.money(plan.pendingThisCycle)} este ciclo · '
            'ya apartaste ${Formatters.money(plan.setAsideThisCycle)}.',
          ),
          if (plan.behind.isPositive) ...[
            const SizedBox(height: 4),
            _BehindLine(amount: plan.behind),
          ],
          const SizedBox(height: 8),
          Text(
            'Llevas apartado ${Formatters.money(plan.saved)} en total. '
            'Estos pagos equivalen a '
            '${Formatters.money(plan.monthlyEquivalent)} al mes.',
            style: muted,
          ),
        ],
      ),
    );
  }
}

class _BehindLine extends StatelessWidget {
  const new({required this.amount});

  final Money amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Row(
      children: [
        Icon(Icons.error, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Vas atrasado ${Formatters.money(amount)} frente a apartar '
            'parejo cada mes.',
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// El orden recomendado para repartir el sueldo, con los valores del ciclo.
class _SalaryOrderCard extends StatelessWidget {
  const new({required this.summary});

  final CycleSummary summary;

  @override
  Widget build(BuildContext context) {
    final cap = summary.dailyCap;
    final steps = [
      (
        Icons.receipt_long,
        'Fijos, cuotas y deudas',
        'Pendientes este ciclo: '
            '${Formatters.money(summary.upcomingFixed.upcomingExpenses)}',
      ),
      (
        Icons.event_repeat,
        'Pagos del año',
        'Falta apartar '
            '${Formatters.money(summary.provisionPlan.pendingThisCycle)}',
      ),
      (
        Icons.savings_outlined,
        'Tu ahorro',
        'Meta del ciclo: ${Formatters.money(summary.savingsTarget)}',
      ),
      (
        Icons.today,
        'Día a día',
        cap == null
            ? 'Lo que quede, repartido en los días que faltan'
            : 'Lo que queda: ${Formatters.money(cap.cap)} por día',
      ),
    ];
    return SectionCard(
      title: 'Orden para usar tu sueldo',
      child: Column(
        children: [
          for (final (i, (icon, title, detail)) in steps.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: CircleAvatar(radius: 16, child: Icon(icon, size: 18)),
              title: Text('${i + 1}. $title'),
              subtitle: Text(detail),
            ),
          Text(
            'Así, lo que gastas en el día a día nunca se come la plata de '
            'tus pagos grandes.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProvisionCard extends StatelessWidget {
  const new({required this.status, required this.category});

  final ProvisionStatus status;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provision = status.provision;
    final color = TrafficLightStyle.color(status.light, theme.colorScheme);
    final progress = status.progress;
    return SectionCard(
      title: provision.name,
      trailing: TrafficLightBadge(
        light: status.light,
        detail: progress == null ? null : Formatters.percent(progress),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryAvatar(category: category, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${Formatters.money(status.saved)} de '
                  '${Formatters.money(status.amount)}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showFormSheet<void>(
                  context,
                  ProvisionFormSheet(provision: provision),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (progress?.fraction ?? 0).clamp(0, 1).toDouble(),
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            semanticsLabel: 'Apartado de ${provision.name}',
          ),
          const SizedBox(height: 8),
          Text(_dueText(status)),
          if (!status.isReady)
            Text(
              status.pendingThisCycle.isPositive
                  ? 'Este ciclo: aparta '
                        '${Formatters.money(status.pendingThisCycle)}'
                  : 'Este ciclo ya apartaste lo necesario.',
            ),
          if (status.behind.isPositive && !status.isReady)
            Text(
              'Atrasado ${Formatters.money(status.behind)}',
              style: TextStyle(color: color),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.savings_outlined),
                label: const Text('Apartar'),
                onPressed: () =>
                    showFormSheet<void>(context, SetAsideSheet(status: status)),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Ya lo pagué'),
                onPressed: () => showFormSheet<void>(
                  context,
                  PayProvisionSheet(status: status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _dueText(ProvisionStatus status) {
    final date = Formatters.shortDate(status.provision.nextDue);
    final days = status.daysUntilDue;
    final every = status.provision.everyMonths == 12
        ? 'cada año'
        : 'cada ${status.provision.everyMonths} meses';
    if (status.isOverdue) return 'Venció el $date. ¿Ya lo pagaste?';
    if (days == 0) return 'Se paga hoy · $every';
    return 'Se paga el $date (en $days días) · $every';
  }
}

class _PausedTile extends StatelessWidget {
  const new({required this.provision});

  final Provision provision;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.pause_circle_outline),
        title: Text(provision.name),
        subtitle: const Text('Pausado: no pide apartar'),
        trailing: Text(Formatters.money(provision.amount)),
        onTap: () => showFormSheet<void>(
          context,
          ProvisionFormSheet(provision: provision),
        ),
      ),
    );
  }
}

/// Atajos con los pagos más comunes. Los valores se pueden cambiar.
class _TemplatesCard extends StatelessWidget {
  const new({required this.existing});

  final Set<String> existing;

  @override
  Widget build(BuildContext context) {
    final available = ProvisionTemplate.all
        .where((t) => !existing.contains(t.name))
        .toList();
    if (available.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: 'Agregar rápido',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final template in available)
            ActionChip(
              avatar: Icon(
                CategoryStyle.icon(_iconKey(template.categoryId)),
                size: 18,
              ),
              label: Text(template.name),
              onPressed: () => showFormSheet<void>(
                context,
                ProvisionFormSheet(template: template),
              ),
            ),
        ],
      ),
    );
  }

  static String _iconKey(String categoryId) =>
      categoryId.replaceFirst('seed-expense-', '');
}
