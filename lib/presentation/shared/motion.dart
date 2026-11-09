import 'package:finance_app/domain/shared/money.dart';
import 'package:flutter/material.dart';

/// Movimiento de Roka: corto, con frenado suave y nunca bloquea. Si el
/// teléfono pide quitar animaciones (accesibilidad), todo aparece al
/// instante.
abstract final class Motion {
  /// Cambios pequeños: color, tamaño de un indicador.
  static const quick = Duration(milliseconds: 180);

  /// Entradas de tarjetas y cambio de sección.
  static const medium = Duration(milliseconds: 320);

  /// Gráficas que crecen y montos que cuentan.
  static const slow = Duration(milliseconds: 650);

  /// Retraso entre tarjetas que entran en cascada.
  static const staggerStep = Duration(milliseconds: 45);

  /// Tope de la cascada: lo que entra más abajo no espera de más.
  static const maxStaggerSteps = 6;

  /// Desplazamiento vertical de entrada (fracción de la altura propia).
  static const enterOffset = 0.06;

  static const emphasized = Curves.easeOutCubic;
  static const settle = Curves.easeInOutCubic;

  /// `false` cuando el sistema pide reducir el movimiento.
  static bool enabled(BuildContext context) =>
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
}

/// Aparece subiendo un poco y con fundido la primera vez que se construye.
/// [index] escalona la entrada de una lista de tarjetas.
class FadeSlideIn extends StatefulWidget {
  const new({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  // Sin temporizadores: el retraso de la cascada es parte de la misma
  // animación (un Interval), así no queda nada pendiente al salir.
  late final int _steps = widget.index.clamp(0, Motion.maxStaggerSteps);
  late final _controller = AnimationController(
    vsync: this,
    duration: Motion.medium + Motion.staggerStep * _steps,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      (Motion.staggerStep * _steps).inMicroseconds /
          _controller.duration!.inMicroseconds,
      1,
      curve: Motion.emphasized,
    ),
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.enabled(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, Motion.enterOffset),
        end: Offset.zero,
      ).animate(_curve),
      child: widget.child,
    ),
  );
}

/// Envuelve cada hijo en [FadeSlideIn] con su turno en la cascada.
List<Widget> staggered(List<Widget> children) => [
  for (final (i, child) in children.indexed)
    FadeSlideIn(index: i, child: child),
];

/// Repite una entrada suave cada vez que [active] pasa a `true` (cambio de
/// sección sin perder el estado de la pantalla).
class RevealOnActive extends StatefulWidget {
  const new({required this.active, required this.child, super.key});

  final bool active;
  final Widget child;

  @override
  State<RevealOnActive> createState() => _RevealOnActiveState();
}

class _RevealOnActiveState extends State<RevealOnActive>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Motion.medium,
    value: 1,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.emphasized,
  );

  static const _offset = 0.03;

  /// La sección entra creciendo un poco: se nota el cambio sin marear.
  static const _startScale = 0.98;

  /// Veces que la sección se ha mostrado; las gráficas se repiten en cada
  /// visita.
  late int _visits = widget.active ? 1 : 0;

  @override
  void didUpdateWidget(RevealOnActive old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _visits++;
      if (Motion.enabled(context)) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SectionScope(
    active: widget.active,
    visits: _visits,
    child: FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, _offset),
          end: Offset.zero,
        ).animate(_curve),
        child: ScaleTransition(
          scale: Tween<double>(begin: _startScale, end: 1).animate(_curve),
          child: widget.child,
        ),
      ),
    ),
  );
}

/// Dice a las gráficas de una sección si se está viendo y cuántas veces se
/// ha mostrado: las secciones viven construidas aunque no se vean.
class _SectionScope extends InheritedWidget {
  const new({required this.active, required this.visits, required super.child});

  final bool active;
  final int visits;

  @override
  bool updateShouldNotify(_SectionScope old) =>
      old.active != active || old.visits != visits;
}

/// Progreso 0→1 para que una gráfica crezca al aparecer, otra vez cuando
/// cambian sus datos ([replayKey]) y cada vez que se vuelve a su sección
/// (en una sección oculta espera, para no animarse sin que nadie la vea).
class ChartReveal extends StatefulWidget {
  const new({required this.replayKey, required this.builder, super.key});

  /// Cambia cuando cambian los datos (p. ej. `Object.hashAll(values)`).
  final Object? replayKey;
  final Widget Function(BuildContext context, double progress) builder;

  @override
  State<ChartReveal> createState() => _ChartRevealState();
}

class _ChartRevealState extends State<ChartReveal>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.emphasized,
  );

  /// Visita de la sección en la que ya se animó (`-1`: nunca).
  var _playedVisit = -1;
  var _visible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final section = context.dependOnInheritedWidgetOfExactType<_SectionScope>();
    _visible = section?.active ?? true;
    final visit = section?.visits ?? 0;
    if (_visible && visit != _playedVisit) {
      _playedVisit = visit;
      _play();
    }
  }

  @override
  void didUpdateWidget(ChartReveal old) {
    super.didUpdateWidget(old);
    if (old.replayKey != widget.replayKey && _visible) _play();
  }

  void _play() {
    if (Motion.enabled(context)) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    builder: (context, _) => widget.builder(context, _curve.value),
  );
}

/// Monto que cuenta desde el valor anterior hasta el nuevo (desde cero la
/// primera vez). Solo anima lo que se pinta: el valor real nunca cambia.
class AnimatedMoneyText extends StatelessWidget {
  const new({
    required this.amount,
    required this.format,
    this.style,
    super.key,
  });

  final Money amount;
  final String Function(Money) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (!Motion.enabled(context)) return Text(format(amount), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amount.cents.toDouble()),
      duration: Motion.slow,
      curve: Motion.emphasized,
      builder: (context, cents, _) =>
          Text(format(Money(cents.round())), style: style),
    );
  }
}

/// Barra de progreso que se llena desde cero al aparecer y se desliza al
/// nuevo valor cuando cambia.
class AnimatedProgressBar extends StatelessWidget {
  const new({
    required this.value,
    this.minHeight = 6,
    this.color,
    this.backgroundColor,
    this.semanticsLabel,
    this.semanticsValue,
    super.key,
  });

  /// De 0 a 1 (se recorta).
  final double value;
  final double minHeight;
  final Color? color;
  final Color? backgroundColor;
  final String? semanticsLabel;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.clamp(0, 1)),
    duration: Motion.enabled(context) ? Motion.slow : Duration.zero,
    curve: Motion.emphasized,
    builder: (context, progress, _) => LinearProgressIndicator(
      value: progress,
      minHeight: minHeight,
      color: color,
      backgroundColor: backgroundColor,
      borderRadius: BorderRadius.circular(minHeight / 2),
      semanticsLabel: semanticsLabel,
      semanticsValue: semanticsValue,
    ),
  );
}

/// Muestra [child] de izquierda a derecha según [progress] (0→1): para
/// gráficas que "se dibujan" al aparecer, dentro de un [ChartReveal].
class WipeReveal extends StatelessWidget {
  const new({required this.progress, required this.child, super.key});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ClipRect(clipper: _WipeClipper(progress), child: child);
}

class _WipeClipper extends CustomClipper<Rect> {
  new(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress.clamp(0, 1), size.height);

  @override
  bool shouldReclip(_WipeClipper old) => old.progress != progress;
}
