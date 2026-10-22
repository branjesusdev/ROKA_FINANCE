import 'package:finance_app/application/dashboard/salary_forecast.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/motion.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:flutter/material.dart';

/// Barras de lo libre acumulado al cerrar este ciclo y los siguientes.
/// Verde arriba de cero, rojo abajo (estarías corto). Con [before], una
/// marca muestra cómo quedaría sin el gasto que simulas.
class ForecastChart extends StatelessWidget {
  const new({required this.forecast, this.before, super.key});

  final SalaryForecast forecast;

  /// Proyección sin el gasto (para comparar).
  final SalaryForecast? before;

  static const _height = 150.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final balances = forecast.balances;
    final labels = [
      'Este',
      for (final m in forecast.months) Formatters.monthAbbr(m.payday),
    ];
    final short = forecast.firstShort;
    final summary = forecast.shortThisCycle
        ? 'Este ciclo cerraría en rojo por '
              '${Formatters.money(forecast.cycleEnd.abs)}.'
        : short != null
        ? 'En ${Formatters.monthAbbr(short.payday)} estarías corto por '
              '${Formatters.money(short.balance.abs)}.'
        : 'Ningún mes queda en rojo. En '
              '${Formatters.monthAbbr(forecast.months.last.payday)} '
              'llevarías ${Formatters.money(forecast.last)} de más.';
    final points = [
      for (var i = 0; i < balances.length; i++)
        '${labels[i]} ${Formatters.money(balances[i])}',
    ];
    return Semantics(
      label: 'Proyección de lo libre acumulado: ${points.join(', ')}. $summary',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _height,
            child: ChartReveal(
              replayKey: Object.hashAll(balances.map((b) => b.cents)),
              builder: (context, progress) => CustomPaint(
                painter: _BarsPainter(
                  progress: progress,
                  values: [for (final b in balances) b.cents.toDouble()],
                  ghosts: before == null
                      ? null
                      : [for (final b in before!.balances) b.cents.toDouble()],
                  positive: StatusColors.okOf(scheme),
                  negative: scheme.error,
                  ghost: scheme.onSurfaceVariant,
                  axis: scheme.outlineVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                forecast.staysPositive
                    ? Icons.trending_up
                    : Icons.warning_amber_outlined,
                size: 18,
                color: forecast.staysPositive
                    ? StatusColors.okOf(scheme)
                    : scheme.error,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(summary, style: theme.textTheme.bodyMedium)),
            ],
          ),
          if (before != null) ...[
            const SizedBox(height: 4),
            Text(
              'La raya gris es cómo quedarías sin este gasto.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  new({
    required this.progress,
    required this.values,
    required this.ghosts,
    required this.positive,
    required this.negative,
    required this.ghost,
    required this.axis,
  });

  final List<double> values;
  final List<double>? ghosts;
  final Color positive;
  final Color negative;
  final Color ghost;
  final Color axis;

  /// 0→1: las barras crecen desde la línea del cero.
  final double progress;

  /// Parte del ancho de cada columna que ocupa la barra.
  static const _barShare = 0.56;
  static const _radius = Radius.circular(4);
  static const _ghostStroke = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...values, ...?ghosts];
    final top = all.fold<double>(0, (m, v) => v > m ? v : m);
    final bottom = all.fold<double>(0, (m, v) => v < m ? v : m);
    final span = top - bottom == 0 ? 1.0 : top - bottom;
    double y(double v) => (top - v) / span * size.height;
    final zero = y(0);
    final column = size.width / values.length;
    final barWidth = column * _barShare;
    for (var i = 0; i < values.length; i++) {
      final left = column * i + (column - barWidth) / 2;
      final v = values[i] * progress;
      final rect = Rect.fromLTRB(
        left,
        v >= 0 ? y(v) : zero,
        left + barWidth,
        v >= 0 ? zero : y(v),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, _radius),
        Paint()..color = v >= 0 ? positive : negative,
      );
      final g = ghosts?[i];
      if (g != null && g != v) {
        canvas.drawLine(
          Offset(left - 2, y(g)),
          Offset(left + barWidth + 2, y(g)),
          Paint()
            ..color = ghost
            ..strokeWidth = _ghostStroke,
        );
      }
    }
    canvas.drawLine(
      Offset(0, zero),
      Offset(size.width, zero),
      Paint()
        ..color = axis
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.values != values ||
      old.ghosts != ghosts ||
      old.progress != progress ||
      old.positive != positive ||
      old.negative != negative;
}

/// Tarjeta "¿Estaré corto?": próximos meses con tu sueldo.
class ForecastSummary extends StatelessWidget {
  const new({required this.forecast, super.key});

  final SalaryForecast forecast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = forecast.months.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ForecastChart(forecast: forecast),
        const SizedBox(height: 8),
        Text(
          'Cada mes: sueldo ${Formatters.money(first.income)} − fijos '
          '${Formatters.money(first.fixedExpenses)} − pagos del año '
          '${Formatters.money(first.setAside)} − gasto variable '
          '${Formatters.money(first.dayToDay)} = ${signedMoney(first.net)}.',
          style: theme.textTheme.bodySmall,
        ),
        Text(forecastBasis(forecast), style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// De dónde salen el sueldo y el gasto de la proyección.
String forecastBasis(SalaryForecast forecast) {
  final salary = switch (forecast.source) {
    SalarySource.configured => 'tu sueldo de Ajustes',
    SalarySource.fixedIncome => 'tu sueldo fijo',
    SalarySource.history => 'el promedio de tus últimos sueldos',
    SalarySource.thisCycle => 'el sueldo de este ciclo',
    SalarySource.unknown =>
      'sin sueldo (escríbelo en Ajustes › Mi sueldo para proyectar bien)',
  };
  final spend = forecast.dayToDayFromHistory
      ? 'tu gasto variable promedio'
      : 'que gastas tu tope y ahorras tu meta';
  return 'Estimado con $salary y $spend. No es una promesa.';
}

/// `Money` con signo para textos cortos.
String signedMoney(Money value) =>
    '${value.isNegative ? '−' : ''}${Formatters.money(value.abs)}';
