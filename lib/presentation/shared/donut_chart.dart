import 'dart:math' as math;

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
        child: CustomPaint(
          painter: _DonutPainter(
            values: values,
            colors: colors,
            strokeWidth: strokeWidth,
            trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Center(child: center),
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
  });

  static const _gap = 0.03;

  final List<double> values;
  final List<Color> colors;
  final double strokeWidth;
  final Color trackColor;

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
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i] / total;
      if (sweep > gap) {
        canvas.drawArc(
          rect,
          start,
          sweep - gap,
          false,
          paint..color = colors[i],
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values != values ||
      old.colors != colors ||
      old.trackColor != trackColor;
}
