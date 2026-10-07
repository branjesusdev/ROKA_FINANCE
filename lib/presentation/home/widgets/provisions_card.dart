import 'package:finance_app/domain/provisions/provision_planner.dart';
import 'package:finance_app/presentation/provisions/provisions_screen.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/traffic_light_badge.dart';
import 'package:flutter/material.dart';

/// "Aparta hoy": la cuota del día para los pagos que no son mensuales
/// (SOAT, matrícula, gimnasio trimestral…). En rojo si vas atrasado.
class ProvisionsCard extends StatelessWidget {
  const new({required this.plan, super.key});

  final ProvisionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    void open() => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProvisionsScreen()));

    if (plan.isEmpty) {
      return SectionCard(
        title: 'Pagos del año',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Pagas gimnasio trimestral, SOAT, tecnomecánica o colegio? '
              'Prográmalos y te digo cuánto apartar cada día.',
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.event_repeat),
              label: const Text('Programar pagos'),
              onPressed: open,
            ),
          ],
        ),
      );
    }

    final today = plan.todaySetAside;
    final next = plan.next;
    final error = theme.colorScheme.error;
    return InkWell(
      onTap: open,
      borderRadius: BorderRadius.circular(12),
      child: SectionCard(
        title: 'Pagos del año',
        trailing: TrafficLightBadge(light: plan.light),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              today == null
                  ? 'Este ciclo ya está apartado'
                  : 'Aparta hoy ${Formatters.money(today)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (plan.pendingThisCycle.isPositive) ...[
              const SizedBox(height: 4),
              Text(
                'Si no, al cierre del ciclo faltarán '
                '${Formatters.money(plan.pendingThisCycle)} para '
                '${_names(plan)}.',
              ),
            ],
            if (plan.behind.isPositive) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.error, size: 18, color: error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Vas atrasado ${Formatters.money(plan.behind)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: error),
                    ),
                  ),
                ],
              ),
            ],
            if (next != null) ...[
              const SizedBox(height: 8),
              Text(
                'Próximo: ${next.provision.name} · '
                '${Formatters.shortDate(next.provision.nextDue)} · llevas '
                '${Formatters.money(next.saved)} de '
                '${Formatters.money(next.amount)}',
                style: muted,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Nombres de los pagos con algo pendiente este ciclo.
  static String _names(ProvisionPlan plan) {
    final names = [
      for (final s in plan.statuses)
        if (s.pendingThisCycle.isPositive) s.provision.name,
    ];
    if (names.length <= 1) return names.join();
    return '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
  }
}
