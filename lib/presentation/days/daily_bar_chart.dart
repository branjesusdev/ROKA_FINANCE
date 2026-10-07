import 'package:finance_app/application/dashboard/daily_spending.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';

/// Barras por día: abajo el día a día (verde si quedó dentro del tope, rojo
/// si lo pasó), encima lo planeado (fijos, mercado…) en gris. La línea
/// punteada es el tope diario. Cada barra tiene su descripción para
/// lectores de pantalla.
class DailyBarChart extends StatelessWidget {
  const new({
    required this.series,
    this.selected,
    this.onSelected,
    this.height = 170,
    super.key,
  });

  final DailySpendingSeries series;
  final DateTime? selected;
  final ValueChanged<DaySpending>? onSelected;
  final double height;

  static const _barWidth = 30.0;
  static const _labelHeight = 34.0;
  static const plannedColor = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final days = series.days;
    if (days.isEmpty) {
      return const Text('Aún no hay días en este ciclo.');
    }
    final cap = series.cap;
    var max = series.maxTotal;
    if (cap != null && cap > max) max = cap;
    if (!max.isPositive) max = const Money.pesos(1);
    final barArea = height - _labelHeight;

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[days.length - 1 - index];
          return _Bar(
            day: day,
            cap: cap,
            max: max,
            barArea: barArea,
            width: _barWidth,
            selected: selected != null && _sameDay(selected!, day.date),
            onTap: onSelected == null ? null : () => onSelected!(day),
          );
        },
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Bar extends StatelessWidget {
  const new({
    required this.day,
    required this.cap,
    required this.max,
    required this.barArea,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final DaySpending day;
  final Money? cap;
  final Money max;
  final double barArea;
  final double width;
  final bool selected;
  final VoidCallback? onTap;

  double _height(Money amount) => barArea * (amount.cents / max.cents);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limit = cap;
    final over = limit != null && day.dayToDay > limit;
    final dayColor = over ? theme.colorScheme.error : theme.colorScheme.primary;
    final label =
        '${Formatters.shortDate(day.date)}: día a día '
        '${Formatters.money(day.dayToDay)}'
        '${over ? ', sobre el tope' : ''}; planeado '
        '${Formatters.money(day.planned)}';

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: width + 8,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: selected
              ? BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Column(
            children: [
              SizedBox(
                height: barArea,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: _height(day.planned),
                          decoration: const BoxDecoration(
                            color: DailyBarChart.plannedColor,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        Container(
                          height: _height(day.dayToDay),
                          decoration: BoxDecoration(
                            color: dayColor,
                            borderRadius: day.planned.isPositive
                                ? null
                                : const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (limit != null && limit.isPositive)
                      Positioned(
                        left: -4,
                        right: -4,
                        bottom: _height(limit),
                        child: _Dashes(color: theme.colorScheme.onSurface),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${day.date.day}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : null,
                ),
              ),
              Icon(
                over ? Icons.arrow_upward : Icons.circle,
                size: 10,
                color: day.total.isPositive
                    ? dayColor
                    : theme.colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dashes extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 4; i++)
        Expanded(
          child: Container(
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            color: color,
          ),
        ),
    ],
  );
}

/// Leyenda con texto (nunca solo color).
class DailyChartLegend extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(Widget mark, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
    Widget box(Color color) => Container(width: 12, height: 12, color: color);
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        item(box(theme.colorScheme.primary), 'Día a día'),
        item(box(theme.colorScheme.error), 'Sobre el tope'),
        item(box(DailyBarChart.plannedColor), 'Fijos y del mes'),
        item(
          SizedBox(
            width: 14,
            child: _Dashes(color: theme.colorScheme.onSurface),
          ),
          'Tope diario',
        ),
      ],
    );
  }
}
