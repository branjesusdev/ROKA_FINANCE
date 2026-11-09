import 'dart:math' as math;

import 'package:finance_app/application/dashboard/cycle_ledger.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/motion.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:flutter/material.dart';

/// "¿Cuánto tengo en total?": lo que va del ciclo más lo que sobró (o
/// faltó) en cada ciclo anterior, con el acumulado ciclo a ciclo.
class CycleLedgerCard extends StatelessWidget {
  const new({required this.ledger, super.key});

  final CycleLedger ledger;

  /// Ciclos cerrados que se listan (los más recientes).
  static const maxRows = 6;

  static const _chartHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = ledger.total;
    final closed = ledger.closed.toList().reversed.take(maxRows).toList();
    return SectionCard(
      title: 'Tu dinero total',
      trailing: Icon(
        total.isNegative ? Icons.trending_down : Icons.account_balance_wallet,
        color: _color(total, scheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedMoneyText(
            amount: total,
            format: Formatters.money,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: _color(total, scheme),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Este ciclo ${Formatters.money(ledger.current)} · de ciclos '
            'anteriores ${_signed(ledger.carried)}. No incluye lo que ya '
            'moviste a metas o pagos del año.',
            style: theme.textTheme.bodySmall,
          ),
          if (ledger.entries.length > 1) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: _chartHeight,
              child: _ResultBars(entries: ledger.entries),
            ),
          ],
          if (closed.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final entry in closed) _LedgerRow(entry: entry),
          ],
        ],
      ),
    );
  }

  static Color _color(Money amount, ColorScheme scheme) =>
      amount.isNegative ? scheme.error : StatusColors.okOf(scheme);

  static String _signed(Money amount) =>
      '${amount.isNegative ? '−' : '+'}${Formatters.money(amount.abs)}';
}

/// Un ciclo cerrado: cuánto sobró o faltó y cómo quedó el acumulado.
class _LedgerRow extends StatelessWidget {
  const new({required this.entry});

  final CycleLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = CycleLedgerCard._color(entry.result, theme.colorScheme);
    final cycle = entry.cycle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            entry.result.isNegative
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Formatters.shortDate(cycle.start)} – '
                  '${Formatters.shortDate(cycle.lastDay)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'Acumulado ${Formatters.money(entry.accumulated)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${entry.result.isNegative ? 'Faltó' : 'Sobró'} '
            '${CycleLedgerCard._signed(entry.result)}',
            style: theme.textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Barras por ciclo desde una línea en cero: arriba lo que sobró (verde),
/// abajo lo que faltó (rojo). Crecen al aparecer.
class _ResultBars extends StatelessWidget {
  const new({required this.entries});

  final List<CycleLedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final summary = entries
        .map(
          (e) =>
              '${Formatters.shortDate(e.cycle.start)}: '
              '${CycleLedgerCard._signed(e.result)}',
        )
        .join(', ');
    return Semantics(
      label: 'Resultado por ciclo: $summary',
      child: ExcludeSemantics(
        child: ChartReveal(
          replayKey: Object.hashAll(entries.map((e) => e.result.cents)),
          builder: (context, progress) => CustomPaint(
            size: Size.infinite,
            painter: _ResultBarsPainter(
              results: [for (final e in entries) e.result.cents],
              progress: progress,
              positive: StatusColors.okOf(scheme),
              negative: scheme.error,
              axis: scheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultBarsPainter extends CustomPainter {
  new({
    required this.results,
    required this.progress,
    required this.positive,
    required this.negative,
    required this.axis,
  });

  final List<int> results;
  final double progress;
  final Color positive;
  final Color negative;
  final Color axis;

  static const _gap = 6.0;
  static const _radius = Radius.circular(4);

  /// El último ciclo (en curso) va más tenue: aún cambia.
  static const _currentAlpha = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty) return;
    final maxUp = results.fold(0, math.max);
    final maxDown = -results.fold(0, math.min);
    final range = maxUp + maxDown;
    final zeroY = range == 0 ? size.height : size.height * maxUp / range;
    final width = (size.width - _gap * (results.length - 1)) / results.length;
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      Paint()..color = axis,
    );
    if (range == 0) return;
    for (final (i, cents) in results.indexed) {
      final height = size.height * cents.abs() / range * progress;
      final left = i * (width + _gap);
      final rect = cents >= 0
          ? Rect.fromLTWH(left, zeroY - height, width, height)
          : Rect.fromLTWH(left, zeroY, width, height);
      final base = cents >= 0 ? positive : negative;
      final isCurrent = i == results.length - 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, _radius),
        Paint()
          ..color = isCurrent ? base.withValues(alpha: _currentAlpha) : base,
      );
    }
  }

  @override
  bool shouldRepaint(_ResultBarsPainter old) =>
      old.progress != progress ||
      old.results != results ||
      old.positive != positive ||
      old.negative != negative;
}
