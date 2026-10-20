import 'package:finance_app/application/advisor/financial_alerts.dart';
import 'package:finance_app/domain/advisor/ai_review.dart';
import 'package:finance_app/domain/fixed/fixed_coverage.dart';
import 'package:flutter/material.dart';

/// Colores de estado: siempre con icono y texto (nunca solo color). El rojo
/// solo para lo que requiere acción.
abstract final class StatusColors {
  static const ok = Color(0xFF15803D);
  static const okOnDark = Color(0xFF86EFAC);
  static const warning = Color(0xFFB45309);
  static const warningOnDark = Color(0xFFFCD34D);
  static const info = Color(0xFF2F6B5E);
  static const infoOnDark = Color(0xFF9FD4C4);

  static Color okOf(ColorScheme s) => _dark(s) ? okOnDark : ok;
  static Color warningOf(ColorScheme s) => _dark(s) ? warningOnDark : warning;
  static Color infoOf(ColorScheme s) => _dark(s) ? infoOnDark : info;

  static bool _dark(ColorScheme s) => s.brightness == Brightness.dark;
}

abstract final class AlertStyle {
  static Color color(AlertSeverity severity, ColorScheme scheme) =>
      switch (severity) {
        AlertSeverity.critical => scheme.error,
        AlertSeverity.warning => StatusColors.warningOf(scheme),
        AlertSeverity.info => StatusColors.infoOf(scheme),
        AlertSeverity.positive => StatusColors.okOf(scheme),
      };

  static String label(AlertSeverity severity) => switch (severity) {
    AlertSeverity.critical => 'Urgente',
    AlertSeverity.warning => 'Atención',
    AlertSeverity.info => 'Oportunidad',
    AlertSeverity.positive => 'Logro',
  };

  static IconData icon(AlertKind kind) => switch (kind) {
    AlertKind.liquidity => Icons.report_problem_outlined,
    AlertKind.dailyCap => Icons.do_not_disturb_on_outlined,
    AlertKind.fixedNotCovered => Icons.event_busy_outlined,
    AlertKind.provisionBehind => Icons.calendar_month_outlined,
    AlertKind.overBudget => Icons.pie_chart_outline,
    AlertKind.categorySurge => Icons.trending_up,
    AlertKind.expensiveDebt => Icons.credit_card_off_outlined,
    AlertKind.idleMoney => Icons.hourglass_bottom,
    AlertKind.assetDrain => Icons.money_off_outlined,
    AlertKind.emergencyFund => Icons.health_and_safety_outlined,
    AlertKind.goalReached => Icons.emoji_events_outlined,
  };
}

abstract final class PriorityStyle {
  static String label(AdvicePriority priority) => switch (priority) {
    AdvicePriority.high => 'Prioridad alta',
    AdvicePriority.medium => 'Prioridad media',
    AdvicePriority.low => 'Cuando puedas',
  };

  static Color color(AdvicePriority priority, ColorScheme scheme) =>
      switch (priority) {
        AdvicePriority.high => scheme.error,
        AdvicePriority.medium => StatusColors.warningOf(scheme),
        AdvicePriority.low => StatusColors.infoOf(scheme),
      };
}

abstract final class ObligationStyle {
  static String label(ObligationState state) => switch (state) {
    ObligationState.paid => 'Pagado',
    ObligationState.overdue => 'Vencido: sin confirmar',
    ObligationState.covered => 'Cubierto',
    ObligationState.partial => 'Cubierto en parte',
    ObligationState.uncovered => 'Sin cubrir',
  };

  static IconData icon(ObligationState state) => switch (state) {
    ObligationState.paid => Icons.check_circle,
    ObligationState.overdue => Icons.schedule,
    ObligationState.covered => Icons.verified_outlined,
    ObligationState.partial => Icons.timelapse,
    ObligationState.uncovered => Icons.error_outline,
  };

  static Color color(ObligationState state, ColorScheme scheme) =>
      switch (state) {
        ObligationState.paid ||
        ObligationState.covered => StatusColors.okOf(scheme),
        ObligationState.partial ||
        ObligationState.overdue => StatusColors.warningOf(scheme),
        ObligationState.uncovered => scheme.error,
      };
}

/// Etiqueta de estado: icono + texto sobre un fondo suave del mismo color.
class StatusChip extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  static const _backgroundAlpha = 0.12;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _backgroundAlpha),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
