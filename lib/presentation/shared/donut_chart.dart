import 'dart:math' as math;

import 'package:finance_app/presentation/shared/motion.dart';
import 'package:flutter/material.dart';

/// Gráfico de dona simple. La información también se muestra como texto en
/// la leyenda (accesibilidad), así que el gráfico se excluye de semántica.
class DonutChart extends StatelessWidget {
  const new({
    required this.values,
    required this.colors,
    this.size = 140,
    this.strokeWidth = 22,
    this.center,
    super.key,
  }) : assert(values.length == colors.length, 'un color por valor');

  final List<double> values;
  final List<Color> colors;
  final double size;
  final double strokeWidth;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        // Se dibuja en sentido horario al aparecer o al cambiar los datos.
        child: ChartReveal(
          replayKey: Object.hashAll(values),
          builder: (context, progress) => CustomPaint(
            painter: _DonutPainter(
              values: values,
              colors: colors,
              strokeWidth: strokeWidth,
              trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              progress: progress,
            ),
            child: Center(child: center),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  new({
    required this.values,
    required this.colors,
    required this.strokeWidth,
    required this.trackColor,
    required this.progress,
  });

  static const _gap = 0.03;

  final List<double> values;
  final List<Color> colors;
  final double strokeWidth;
  final Color trackColor;

  /// 0→1: cuánto de la vuelta ya se dibujó.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final total = values.fold<double>(0, (sum, v) => sum + v);

    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = trackColor);
    if (total <= 0) return;

    final gap = values.length > 1 ? _gap : 0.0;
    const origin = -math.pi / 2;
    final end = origin + 2 * math.pi * progress;
    var start = origin;
    for (var i = 0; i < values.length; i++) {
      final full = 2 * math.pi * values[i] / total;
      final sweep = math.min(full, end - start);
      if (sweep > gap) {
        canvas.drawArc(
          rect,
          start,
          sweep - gap,
          false,
          paint..color = colors[i],
        );
      }
      start += full;
      if (start >= end) break;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values != values ||
      old.colors != colors ||
      old.trackColor != trackColor ||
      old.progress != progress;
}
