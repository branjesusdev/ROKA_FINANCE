import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:flutter/material.dart';

/// Estilo accesible del semáforo: color + icono + texto (nunca solo color).
abstract final class TrafficLightStyle {
  static Color color(TrafficLight light, ColorScheme scheme) => switch (light) {
    TrafficLight.ok => const Color(0xFF2E7D32),
    TrafficLight.warning => const Color(0xFFB26A00),
    TrafficLight.critical => scheme.error,
  };

  static IconData icon(TrafficLight light) => switch (light) {
    TrafficLight.ok => Icons.check_circle,
    TrafficLight.warning => Icons.warning_amber_rounded,
    TrafficLight.critical => Icons.error,
  };

  static String label(TrafficLight light) => switch (light) {
    TrafficLight.ok => 'Bien',
    TrafficLight.warning => 'Atención',
    TrafficLight.critical => 'Requiere atención',
  };
}

class TrafficLightBadge extends StatelessWidget {
  const new({required this.light, this.detail, super.key});

  final TrafficLight light;

  /// Texto adicional, p. ej. el porcentaje ("45% usado").
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final color = TrafficLightStyle.color(light, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TrafficLightStyle.icon(light), size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            detail == null
                ? TrafficLightStyle.label(light)
                : '${TrafficLightStyle.label(light)} · $detail',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
