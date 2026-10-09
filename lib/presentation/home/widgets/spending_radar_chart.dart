import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gráfica de araña: dos formas (actual y anterior) sobre los mismos ejes,
/// con la misma escala para que se puedan comparar. Valores ≥ 0.
class SpendingRadarChart extends StatelessWidget {
  const new({
    required this.labels,
    required this.current,
    required this.previous,
    required this.currentColor,
    required this.previousColor,
    required this.semanticsLabel,
    this.size = 260,
    super.key,
  }) : assert(labels.length == current.length, 'un valor por eje'),
       assert(labels.length == previous.length, 'un valor por eje');

  final List<String> labels;
  final List<double> current;
  final List<double> previous;
  final Color currentColor;
  final Color previousColor;

  /// Resumen en texto para lectores de pantalla.
  final String semanticsLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RadarPainter(
            labels: labels,
            current: current,
            previous: previous,
            currentColor: currentColor,
            previousColor: previousColor,
            gridColor: theme.colorScheme.outlineVariant,
            labelStyle:
                theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ) ??
                const TextStyle(fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  new({
    required this.labels,
    required this.current,
    required this.previous,
    required this.currentColor,
    required this.previousColor,
    required this.gridColor,
    required this.labelStyle,
  });

  final List<String> labels;
  final List<double> current;
  final List<double> previous;
  final Color currentColor;
  final Color previousColor;
  final Color gridColor;
  final TextStyle labelStyle;

  static const _rings = 4;
  static const _labelGap = 14.0;
  static const _labelSpace = 34.0;
  static const _fillAlpha = 0.28;
  static const _previousFillAlpha = 0.08;
  static const _dotRadius = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final count = labels.length;
    if (count < 3) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _labelSpace;
    final peak = [...current, ...previous].fold<double>(0, math.max);
    final scale = peak <= 0 ? 0.0 : 1 / peak;

    Offset point(int i, double fraction) {
      // Primer eje arriba, en sentido horario.
      final angle = -math.pi / 2 + 2 * math.pi * i / count;
      return center +
          Offset(math.cos(angle), math.sin(angle)) * radius * fraction;
    }

    final grid = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var r = 1; r <= _rings; r++) {
      canvas.drawPath(
        _polygon([for (var i = 0; i < count; i++) point(i, r / _rings)]),
        grid,
      );
    }
    for (var i = 0; i < count; i++) {
      canvas.drawLine(center, point(i, 1), grid);
    }

    void shape(
      List<double> values,
      Color color,
      double fillAlpha, {
      required bool dashed,
    }) {
      final points = [
        for (var i = 0; i < count; i++) point(i, values[i] * scale),
      ];
      final path = _polygon(points);
      canvas
        ..drawPath(path, Paint()..color = color.withValues(alpha: fillAlpha))
        ..drawPath(
          dashed ? _dash(path) : path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = dashed ? 1.5 : 2.5
            ..strokeJoin = StrokeJoin.round,
        );
      if (!dashed) {
        for (final p in points) {
          canvas.drawCircle(p, _dotRadius, Paint()..color = color);
        }
      }
    }

    shape(previous, previousColor, _previousFillAlpha, dashed: true);
    shape(current, currentColor, _fillAlpha, dashed: false);

    for (var i = 0; i < count; i++) {
      final anchor = point(i, 1 + _labelGap / radius);
      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: _labelSpace * 2.4);
      final dx = anchor.dx < center.dx - 1
          ? anchor.dx - painter.width
          : anchor.dx > center.dx + 1
          ? anchor.dx
          : anchor.dx - painter.width / 2;
      final dy = anchor.dy < center.dy - 1
          ? anchor.dy - painter.height
          : anchor.dy > center.dy + 1
          ? anchor.dy
          : anchor.dy - painter.height / 2;
      painter.paint(canvas, Offset(dx, dy));
    }
  }

  static Path _polygon(List<Offset> points) => Path()..addPolygon(points, true);

  static Path _dash(Path source) {
    const dash = 6.0;
    const gap = 4.0;
    final out = Path();
    for (final metric in source.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        out.addPath(metric.extractPath(d, d + dash), Offset.zero);
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.current != current ||
      old.previous != previous ||
      old.labels != labels ||
      old.currentColor != currentColor ||
      old.gridColor != gridColor;
}
