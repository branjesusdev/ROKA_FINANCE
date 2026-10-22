import 'package:finance_app/application/insights/category_report.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/motion.dart';
import 'package:flutter/material.dart';

/// Cómo se dibujan los 12 meses.
enum HistogramStyle {
  /// Barras: comparar mes contra mes.
  bars,

  /// Línea con puntos y área: ver la tendencia.
  line,
}

/// 12 meses en barras o línea: el mes más alto resaltado con su valor, el
/// mes actual en el color principal, una línea punteada con el promedio y
/// el mes elegido (tocar o arrastrar) marcado.
class MonthlyHistogram extends StatelessWidget {
  const new({
    required this.months,
    this.peak,
    this.average,
    this.style = HistogramStyle.bars,
    this.selected,
    this.onSelect,
    this.height = 170,
    super.key,
  });

  /// Ámbar del mes más alto (no es alerta: el rojo se reserva).
  static const peakColor = Color(0xFFE2A52B);

  final List<CategoryMonth> months;
  final CategoryMonth? peak;
  final Money? average;
  final HistogramStyle style;

  /// Índice del mes elegido en [months].
  final int? selected;
  final ValueChanged<int>? onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    void select(Offset position, double width) {
      if (onSelect == null || months.isEmpty) return;
      final index = (position.dx / (width / months.length)).floor();
      onSelect!(index.clamp(0, months.length - 1));
    }

    return Semantics(
      label: [
        for (final m in months.where((m) => m.count > 0))
          '${Formatters.month(m.month)}: ${Formatters.money(m.total)}',
        if (average case final avg?) 'Promedio ${Formatters.money(avg)}',
      ].join('. '),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            onTapDown: (d) => select(d.localPosition, constraints.maxWidth),
            onHorizontalDragUpdate: (d) =>
                select(d.localPosition, constraints.maxWidth),
            child: SizedBox(
              height: height,
              width: double.infinity,
              // Crece desde la base al aparecer, al cambiar de vista o de
              // datos; elegir un mes no lo repite.
              child: ChartReveal(
                replayKey: Object.hash(
                  style,
                  Object.hashAll(months.map((m) => m.total.cents)),
                ),
                builder: (context, progress) => CustomPaint(
                  painter: _HistogramPainter(
                    progress: progress,
                    months: months,
                    peak: peak,
                    average: average,
                    style: style,
                    selected: selected,
                    barColor: scheme.primary.withValues(alpha: 0.28),
                    currentColor: scheme.primary,
                    peakColor: peakColor,
                    averageColor: scheme.onSurfaceVariant,
                    selectedColor: scheme.onSurface,
                    labelStyle: text.labelSmall!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    peakStyle: text.labelSmall!.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  new({
    required this.progress,
    required this.months,
    required this.peak,
    required this.average,
    required this.style,
    required this.selected,
    required this.barColor,
    required this.currentColor,
    required this.peakColor,
    required this.averageColor,
    required this.selectedColor,
    required this.labelStyle,
    required this.peakStyle,
  });

  final List<CategoryMonth> months;
  final CategoryMonth? peak;
  final Money? average;
  final HistogramStyle style;
  final int? selected;
  final Color barColor;
  final Color currentColor;
  final Color peakColor;
  final Color averageColor;
  final Color selectedColor;
  final TextStyle labelStyle;
  final TextStyle peakStyle;

  /// 0→1: altura ya crecida.
  final double progress;

  static const _axisHeight = 18.0;
  static const _topLabel = 18.0;
  static const _gapFactor = 0.28;
  static const _radius = Radius.circular(6);
  static const _dash = 5.0;
  static const _pointRadius = 3.5;
  static const _areaAlpha = 0.14;
  static const _selectionAlpha = 0.08;
  static const _initials = 'EFMAMJJASOND';

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;
    final max = months
        .map((m) => m.total.cents)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final chartHeight = size.height - _axisHeight - _topLabel;
    final slot = size.width / months.length;
    final barWidth = slot * (1 - _gapFactor);
    final baseline = _topLabel + chartHeight;
    double heightOf(CategoryMonth m) =>
        max == 0 ? 0 : chartHeight * progress * m.total.cents / max;
    Color colorOf(int i, CategoryMonth m) {
      if (peak != null && m.month == peak!.month) return peakColor;
      return i == months.length - 1 ? currentColor : barColor;
    }

    if (selected case final i?) {
      canvas.drawRect(
        Rect.fromLTWH(i * slot, _topLabel, slot, chartHeight),
        Paint()..color = selectedColor.withValues(alpha: _selectionAlpha),
      );
    }

    if (style == HistogramStyle.bars) {
      for (final (i, m) in months.indexed) {
        final h = heightOf(m);
        if (h <= 0) continue;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
              i * slot + (slot - barWidth) / 2,
              baseline - h,
              barWidth,
              h,
            ),
            topLeft: _radius,
            topRight: _radius,
          ),
          Paint()..color = colorOf(i, m),
        );
      }
    } else {
      final points = [
        for (final (i, m) in months.indexed)
          Offset(i * slot + slot / 2, baseline - heightOf(m)),
      ];
      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        line.lineTo(p.dx, p.dy);
      }
      final area = Path.from(line)
        ..lineTo(points.last.dx, baseline)
        ..lineTo(points.first.dx, baseline)
        ..close();
      canvas
        ..drawPath(
          area,
          Paint()..color = currentColor.withValues(alpha: _areaAlpha),
        )
        ..drawPath(
          line,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeJoin = StrokeJoin.round
            ..color = currentColor,
        );
      for (final (i, p) in points.indexed) {
        canvas.drawCircle(
          p,
          _pointRadius,
          Paint()..color = colorOf(i, months[i]),
        );
      }
    }

    for (final (i, m) in months.indexed) {
      final isPeak = peak != null && m.month == peak!.month;
      _text(
        canvas,
        _initials[m.month.month - 1],
        isPeak || i == selected ? peakStyle : labelStyle,
        Offset(i * slot + slot / 2, baseline + 2),
      );
      final h = heightOf(m);
      if (isPeak && h > 0) {
        _text(
          canvas,
          Formatters.money(m.total),
          peakStyle,
          Offset(
            (i * slot + slot / 2).clamp(slot * 1.5, size.width - slot * 1.5),
            baseline - h - _topLabel + 2,
          ),
        );
      }
    }

    if (average case final avg? when max > 0) {
      final y = baseline - chartHeight * avg.cents / max;
      final paint = Paint()
        ..color = averageColor
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += _dash * 2) {
        canvas.drawLine(Offset(x, y), Offset(x + _dash, y), paint);
      }
    }
  }

  void _text(Canvas canvas, String text, TextStyle style, Offset topCenter) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(topCenter.dx - painter.width / 2, topCenter.dy),
    );
  }

  @override
  bool shouldRepaint(_HistogramPainter old) =>
      old.months != months ||
      old.peak != peak ||
      old.average != average ||
      old.style != style ||
      old.selected != selected ||
      old.progress != progress;
}
