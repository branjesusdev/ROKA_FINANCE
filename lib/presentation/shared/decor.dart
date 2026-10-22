import 'dart:math' as math;

import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:flutter/material.dart';

/// Figura de fondo de las tarjetas del Inicio.
enum DecorPattern {
  /// Círculo grande, anillo, puntos y curva que sube.
  orbs,

  /// Ondas suaves abajo.
  waves,

  /// Rayas diagonales en la esquina.
  stripes,

  /// Rocas facetadas (la marca Roka) abajo a la derecha.
  rocks,

  /// Sol que sale con rayos.
  sunrise,

  /// Burbujas de distintos tamaños por el borde.
  bubbles,

  /// Montañas en capas.
  peaks,
}

/// "Arte del día": la base casi negra de siempre con dos brillos de color
/// vívido (estilo Spotify) y una textura sutil distinta. Cambia cada día;
/// los brillos se limitan a [maxGlowAlpha] para que el texto blanco, el
/// gris claro ([AppTheme.onHeroMuted]) y el lima sigan en ≥ 7:1 incluso
/// donde el brillo es más fuerte (lo verifica un test).
@immutable
final class DailyArt {
  const new({
    required this.name,
    required this.glow,
    required this.secondGlow,
    required this.pattern,
  });

  final String name;
  final Color glow;
  final Color secondGlow;
  final DecorPattern pattern;

  /// Opacidad máxima de un brillo sobre la base.
  static const maxGlowAlpha = 0.16;

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppTheme.heroBase, AppTheme.heroBaseEnd],
  );

  List<Color> get colors => [glow, secondGlow];

  /// Sin rosados, morados ni rojos (el rojo es para alertas).
  static const all = <DailyArt>[
    DailyArt(
      name: 'Volt',
      glow: AppTheme.accent,
      secondGlow: AppTheme.cyan,
      pattern: DecorPattern.orbs,
    ),
    DailyArt(
      name: 'Océano',
      glow: AppTheme.cyan,
      secondGlow: AppTheme.blue,
      pattern: DecorPattern.waves,
    ),
    DailyArt(
      name: 'Atardecer',
      glow: AppTheme.orange,
      secondGlow: AppTheme.sun,
      pattern: DecorPattern.sunrise,
    ),
    DailyArt(
      name: 'Aurora',
      glow: AppTheme.mint,
      secondGlow: AppTheme.cyan,
      pattern: DecorPattern.peaks,
    ),
    DailyArt(
      name: 'Eléctrico',
      glow: AppTheme.blue,
      secondGlow: AppTheme.accent,
      pattern: DecorPattern.stripes,
    ),
    DailyArt(
      name: 'Dorado',
      glow: AppTheme.sun,
      secondGlow: AppTheme.accent,
      pattern: DecorPattern.bubbles,
    ),
    DailyArt(
      name: 'Roca',
      glow: AppTheme.mint,
      secondGlow: AppTheme.orange,
      pattern: DecorPattern.rocks,
    ),
  ];

  /// El arte de [day]: rota uno por día.
  static DailyArt forDay(DateTime day) {
    final number =
        DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return all[number % all.length];
  }
}

/// Figuras decorativas para dar vida a banners y tarjetas héroe. No
/// transmiten datos: se excluyen de la accesibilidad, van detrás del
/// contenido y se quedan en bordes y esquinas.
class DecorBackdrop extends StatelessWidget {
  const new({
    required this.child,
    required this.colors,
    this.gradient,
    this.pattern = DecorPattern.orbs,
    this.radius = 28,
    this.padding = const EdgeInsets.all(20),
    this.intensity = 1,
    this.glow = false,
    super.key,
  });

  /// Fondo del arte del día.
  factory daily(
    DailyArt art, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    double intensity = 1,
    Key? key,
  }) => DecorBackdrop(
    colors: art.colors,
    gradient: DailyArt.gradient,
    pattern: art.pattern,
    glow: true,
    padding: padding,
    intensity: intensity,
    key: key,
    child: child,
  );

  final Widget child;

  /// Colores de las figuras (se usan con transparencia).
  final List<Color> colors;
  final Gradient? gradient;
  final DecorPattern pattern;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// Multiplica la opacidad de las figuras (menos = más contraste para el
  /// texto encima).
  final double intensity;

  /// Brillos de color difuminados en dos esquinas (arte del día); las
  /// figuras pasan a ser una textura blanca muy tenue.
  final bool glow;

  static const _borderAlpha = 0.08;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: CustomPaint(
          painter: glow
              ? _GlowPainter(colors, pattern)
              : _DecorPainter(colors, pattern, intensity),
          foregroundPainter: glow ? _HairlinePainter(radius) : null,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Borde de 1 px blanco muy tenue: efecto vidrio.
class _HairlinePainter extends CustomPainter {
  new(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      Radius.circular(radius),
    ),
    Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: DecorBackdrop._borderAlpha),
  );

  @override
  bool shouldRepaint(_HairlinePainter old) => old.radius != radius;
}

/// Dos brillos difuminados + textura blanca tenue del patrón del día.
class _GlowPainter extends CustomPainter {
  new(this.colors, this.pattern);

  final List<Color> colors;
  final DecorPattern pattern;

  /// La textura casi no se ve: da ritmo sin competir con el texto.
  static const _textureIntensity = 0.2;

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty || size.isEmpty) return;
    final short = math.min(size.width, size.height);
    void glowAt(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: DailyArt.maxGlowAlpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    glowAt(Offset(size.width * 0.95, 0), short * 0.95, colors.first);
    glowAt(Offset(0, size.height), short * 0.8, colors[1 % colors.length]);
    _DecorPainter(
      const [Colors.white],
      pattern,
      _textureIntensity,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.colors != colors || old.pattern != pattern;
}

class _DecorPainter extends CustomPainter {
  new(this.colors, this.pattern, this.intensity);

  final List<Color> colors;
  final DecorPattern pattern;
  final double intensity;

  static const _fillAlpha = 0.16;
  static const _strokeAlpha = 0.28;
  static const _dotAlpha = 0.3;
  static const _dotSpacing = 12.0;

  Color _color(int i, double alpha) =>
      colors[i % colors.length].withValues(alpha: alpha * intensity);

  Paint _fill(int i, [double alpha = _fillAlpha]) =>
      Paint()..color = _color(i, alpha);

  Paint _stroke(int i, double width, [double alpha = _strokeAlpha]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..color = _color(i, alpha);

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty || size.isEmpty) return;
    switch (pattern) {
      case DecorPattern.orbs:
        _orbs(canvas, size);
      case DecorPattern.waves:
        _waves(canvas, size);
      case DecorPattern.stripes:
        _stripes(canvas, size);
      case DecorPattern.rocks:
        _rocks(canvas, size);
      case DecorPattern.sunrise:
        _sunrise(canvas, size);
      case DecorPattern.bubbles:
        _bubbles(canvas, size);
      case DecorPattern.peaks:
        _peaks(canvas, size);
    }
  }

  void _orbs(Canvas canvas, Size size) {
    final short = math.min(size.width, size.height);
    canvas
      ..drawCircle(
        Offset(size.width + short * 0.05, -short * 0.1),
        short * 0.45,
        _fill(0),
      )
      ..drawCircle(
        Offset(short * 0.05, size.height - short * 0.05),
        short * 0.32,
        _stroke(1, 10),
      );
    final dot = _fill(2, _dotAlpha);
    final origin = Offset(size.width * 0.62, 14);
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 5; c++) {
        canvas.drawCircle(
          origin + Offset(c * _dotSpacing, r * _dotSpacing),
          2,
          dot,
        );
      }
    }
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.92)
        ..cubicTo(
          size.width * 0.3,
          size.height * 0.98,
          size.width * 0.55,
          size.height * 0.62,
          size.width,
          size.height * 0.7,
        ),
      _stroke(3, 3, 0.22),
    );
  }

  void _waves(Canvas canvas, Size size) {
    const waves = 3;
    for (var i = 0; i < waves; i++) {
      final base = size.height * (0.78 + i * 0.08);
      final amplitude = 10.0 + i * 4;
      final path = Path()..moveTo(0, base);
      for (var x = 0.0; x <= size.width; x += 8) {
        path.lineTo(
          x,
          base + math.sin(x / size.width * math.pi * 3 + i) * amplitude,
        );
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, _fill(i, 0.1));
    }
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.12),
      18,
      _stroke(0, 3),
    );
  }

  void _stripes(Canvas canvas, Size size) {
    const count = 9;
    const gap = 16.0;
    for (var i = 0; i < count; i++) {
      final start = size.width * 0.55 + i * gap;
      canvas.drawLine(
        Offset(start, 0),
        Offset(start + size.height * 0.45, size.height * 0.45),
        _stroke(i % 2, 4, 0.16),
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.95),
      size.height * 0.18,
      _fill(2, 0.12),
    );
  }

  void _rocks(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final facets = <(List<Offset>, int, double)>[
      (
        [Offset(w * 0.62, h), Offset(w * 0.78, h * 0.72), Offset(w * 0.9, h)],
        0,
        0.18,
      ),
      (
        [Offset(w * 0.78, h * 0.72), Offset(w * 0.9, h), Offset(w, h * 0.8)],
        1,
        0.14,
      ),
      (
        [
          Offset(w * 0.78, h * 0.72),
          Offset(w * 0.9, h * 0.62),
          Offset(w, h * 0.8),
        ],
        2,
        0.2,
      ),
      (
        [Offset(w * 0.9, h * 0.62), Offset(w, h * 0.55), Offset(w, h * 0.8)],
        0,
        0.12,
      ),
    ];
    for (final (points, color, alpha) in facets) {
      canvas.drawPath(Path()..addPolygon(points, true), _fill(color, alpha));
    }
    // Línea que sube sobre la roca.
    canvas
      ..drawPath(
        Path()
          ..moveTo(w * 0.58, h * 0.9)
          ..lineTo(w * 0.72, h * 0.66)
          ..lineTo(w * 0.8, h * 0.74)
          ..lineTo(w * 0.96, h * 0.46),
        _stroke(1, 3),
      )
      ..drawCircle(Offset(w * 0.06, h * 0.08), 26, _stroke(2, 6, 0.18));
  }

  void _sunrise(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.86, size.height * 1.02);
    final radius = math.min(size.width, size.height) * 0.22;
    canvas.drawCircle(center, radius, _fill(0, 0.22));
    const rays = 9;
    for (var i = 0; i < rays; i++) {
      final angle = math.pi + i * math.pi / (rays - 1);
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius + 8),
        center + direction * (radius + 30),
        _stroke(1, 3, 0.24),
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.1),
      40,
      _fill(2, 0.1),
    );
  }

  void _bubbles(Canvas canvas, Size size) {
    // Posiciones fijas (relativas) para que no "salten" entre redibujos.
    const bubbles = <(double, double, double, int)>[
      (0.92, 0.12, 30, 0),
      (0.82, 0.3, 12, 1),
      (0.97, 0.45, 18, 2),
      (0.88, 0.62, 8, 0),
      (0.95, 0.82, 24, 1),
      (0.04, 0.9, 20, 2),
      (0.12, 0.97, 9, 0),
    ];
    for (final (x, y, r, color) in bubbles) {
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        r,
        r > 15 ? _fill(color, 0.14) : _stroke(color, 2.5, 0.3),
      );
    }
  }

  void _peaks(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final back = Path()
      ..moveTo(w * 0.35, h)
      ..lineTo(w * 0.62, h * 0.72)
      ..lineTo(w * 0.75, h * 0.82)
      ..lineTo(w * 0.9, h * 0.6)
      ..lineTo(w, h * 0.7)
      ..lineTo(w, h)
      ..close();
    final front = Path()
      ..moveTo(w * 0.5, h)
      ..lineTo(w * 0.72, h * 0.84)
      ..lineTo(w * 0.85, h * 0.9)
      ..lineTo(w, h * 0.8)
      ..lineTo(w, h)
      ..close();
    canvas
      ..drawPath(back, _fill(1, 0.12))
      ..drawPath(front, _fill(0))
      ..drawCircle(Offset(w * 0.9, h * 0.14), 14, _fill(2, _strokeAlpha));
  }

  @override
  bool shouldRepaint(_DecorPainter old) =>
      old.colors != colors ||
      old.pattern != pattern ||
      old.intensity != intensity;
}
