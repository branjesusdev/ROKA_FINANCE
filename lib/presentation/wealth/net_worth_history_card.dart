import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/domain/wealth/net_worth_snapshot.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Evolución mensual del patrimonio neto y cuánto es líquido.
class NetWorthHistoryCard extends ConsumerWidget {
  const new({super.key});

  /// Meses que se dibujan como máximo.
  static const maxMonths = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(netWorthHistoryProvider).value ?? const [];
    final assets = ref.watch(assetsProvider).value ?? const <Asset>[];
    final recent = history.length > maxMonths
        ? history.sublist(history.length - maxMonths)
        : history;
    final byLiquidity = {
      for (final l in Liquidity.values)
        l: Money.sum(
          assets
              .where((a) => a.effectiveLiquidity == l)
              .map((a) => a.currentValue),
        ),
    };
    final monthlyNet = Money.sum(assets.map((a) => a.monthlyNet));
    return SectionCard(
      title: 'Evolución',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.length < 2)
            Text(
              'Cada mes la app guarda una foto de tu patrimonio. Desde el '
              'segundo mes verás aquí si sube o baja.',
              style: theme.textTheme.bodyMedium,
            )
          else
            _Chart(points: recent),
          const SizedBox(height: 16),
          Text('Qué tan rápido es dinero', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: LabeledValue(
                  label: 'Hoy mismo',
                  value: Formatters.money(byLiquidity[Liquidity.high]!),
                ),
              ),
              Expanded(
                child: LabeledValue(
                  label: 'Semanas',
                  value: Formatters.money(byLiquidity[Liquidity.medium]!),
                ),
              ),
              Expanded(
                child: LabeledValue(
                  label: 'Meses',
                  value: Formatters.money(byLiquidity[Liquidity.low]!),
                ),
              ),
            ],
          ),
          if (!monthlyNet.isZero) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  monthlyNet.isNegative ? Icons.money_off : Icons.attach_money,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    monthlyNet.isNegative
                        ? 'Tus bienes te cuestan '
                              '${Formatters.money(monthlyNet.abs)} al mes '
                              'más de lo que producen.'
                        : 'Tus bienes te dejan '
                              '${Formatters.money(monthlyNet)} al mes '
                              'después de sus costos.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const new({required this.points});

  final List<NetWorthSnapshot> points;

  static const _height = 140.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = points.first;
    final last = points.last;
    final change = last.total - first.total;
    final color = theme.colorScheme.primary;
    return Semantics(
      label:
          'Patrimonio neto de ${Formatters.month(first.month)} a '
          '${Formatters.month(last.month)}: de '
          '${Formatters.money(first.total)} a '
          '${Formatters.money(last.total)}.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                change.isNegative ? Icons.trending_down : Icons.trending_up,
                size: 18,
                color: change.isNegative ? theme.colorScheme.error : color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${change.isNegative ? 'Bajó' : 'Subió'} '
                  '${Formatters.money(change.abs)} desde '
                  '${Formatters.month(first.month)}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _height,
            width: double.infinity,
            child: CustomPaint(
              painter: _LinePainter(
                values: [for (final p in points) p.total.cents.toDouble()],
                color: color,
                grid: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.month(first.month),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                Formatters.month(last.month),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  new({required this.values, required this.color, required this.grid});

  final List<double> values;
  final Color color;
  final Color grid;

  static const _stroke = 3.0;
  static const _dot = 4.0;
  static const _fillAlpha = 0.12;

  @override
  void paint(Canvas canvas, Size size) {
    var min = values.reduce((a, b) => a < b ? a : b);
    var max = values.reduce((a, b) => a > b ? a : b);
    if (min == max) {
      min -= 1;
      max += 1;
    }
    Offset point(int i) => Offset(
      values.length == 1 ? 0 : size.width * i / (values.length - 1),
      size.height -
          (values[i] - min) / (max - min) * (size.height - _dot * 2) -
          _dot,
    );
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final y in [0.0, size.height / 2, size.height]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawPath(fill, Paint()..color = color.withValues(alpha: _fillAlpha))
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(point(values.length - 1), _dot, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.color != color || old.grid != grid;
}
