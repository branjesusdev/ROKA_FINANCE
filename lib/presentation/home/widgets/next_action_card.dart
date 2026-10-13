import 'package:finance_app/application/advisor/financial_alerts.dart';
import 'package:finance_app/domain/advisor/ai_review.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "¿Qué hago ahora?": la recomendación prioritaria de la IA (si está
/// activa) y las alertas calculadas por reglas, cada una con su acción.
class NextActionCard extends ConsumerWidget {
  const new({required this.onOpenCfo, super.key});

  final VoidCallback onOpenCfo;

  static const maxAlerts = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(financialAlertsProvider).value ?? const [];
    final review = ref.watch(latestAiReviewProvider).value;
    final top = review?.top;
    final shown = alerts
        .where((a) => a.severity != AlertSeverity.info || top == null)
        .take(maxAlerts)
        .toList();
    if (top == null && shown.isEmpty) {
      return SectionCard(
        title: 'Qué hacer ahora',
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: StatusColors.okOf(Theme.of(context).colorScheme),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Todo en orden: tus pagos están cubiertos y no hay alertas. '
                'Sigue registrando tus gastos.',
              ),
            ),
          ],
        ),
      );
    }
    return SectionCard(
      title: 'Qué hacer ahora',
      trailing: TextButton(onPressed: onOpenCfo, child: const Text('Ver todo')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (top != null && review != null)
            _AiTop(recommendation: top, review: review),
          for (final alert in shown) AlertTile(alert: alert),
        ],
      ),
    );
  }
}

class _AiTop extends StatelessWidget {
  const new({required this.recommendation, required this.review});

  final AiRecommendation recommendation;
  final AiReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tu CFO con IA · ${Formatters.shortDate(review.createdAt)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              StatusChip(
                icon: Icons.flag_outlined,
                label: PriorityStyle.label(recommendation.priority),
                color: PriorityStyle.color(recommendation.priority, scheme),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (recommendation.action.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              recommendation.action,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Alerta por reglas: icono + nivel + título + acción.
class AlertTile extends StatelessWidget {
  const new({required this.alert, this.showDetail = false, super.key});

  final FinancialAlert alert;
  final bool showDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AlertStyle.color(alert.severity, theme.colorScheme);
    return Semantics(
      container: true,
      label: '${AlertStyle.label(alert.severity)}: ${alert.title}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(AlertStyle.icon(alert.kind), size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AlertStyle.label(alert.severity).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(alert.title, style: theme.textTheme.titleSmall),
                  if (showDetail) ...[
                    const SizedBox(height: 2),
                    Text(alert.detail, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    alert.action,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
