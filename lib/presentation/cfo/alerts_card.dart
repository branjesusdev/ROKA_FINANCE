import 'package:finance_app/presentation/home/widgets/next_action_card.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Todas las alertas calculadas por reglas (sin IA ni internet).
class AlertsCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(financialAlertsProvider).value ?? const [];
    return SectionCard(
      title: 'Alertas de tus reglas',
      child: alerts.isEmpty
          ? const Text(
              'Nada urgente: pagos cubiertos, presupuestos en orden y sin '
              'alzas fuertes. Esto se revisa solo, sin internet.',
            )
          : Column(
              children: [
                for (final alert in alerts)
                  AlertTile(alert: alert, showDetail: true),
              ],
            ),
    );
  }
}
