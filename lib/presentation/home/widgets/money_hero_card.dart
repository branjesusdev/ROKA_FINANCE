import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/money_overview.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';

/// Lo primero al abrir: cuánto puedes gastar de verdad (no el saldo), y de
/// dónde sale ese número. Responde "¿cuánto tengo?", "¿cuánto debo
/// reservar?" y "¿cuánto puedo gastar hoy?".
class MoneyHeroCard extends StatelessWidget {
  const new({required this.summary, required this.overview, super.key});

  final CycleSummary summary;
  final MoneyOverview overview;

  static const _radius = 28.0;
  static const _barHeight = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : AppTheme.forest;
    const text = Color(0xFFF2F7F4);
    const muted = Color(0xFFB9CBC4);
    final free = overview.free;
    final shortfall = overview.shortfall;
    final perDay = overview.freePerDay;
    final cap = summary.dailyCap;

    return Semantics(
      container: true,
      label:
          'Libre para gastar ${Formatters.money(free)}. Disponible '
          '${Formatters.money(overview.available)}, reservado '
          '${Formatters.money(overview.reserved)}.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: text),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shortfall == null
                          ? 'Libre para gastar hasta tu sueldo'
                          : 'Te falta para cubrir lo reservado',
                      style: theme.textTheme.titleSmall?.copyWith(color: muted),
                    ),
                  ),
                  _DaysLeft(days: summary.daysLeft),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Formatters.money(shortfall ?? free),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: shortfall == null
                        ? AppTheme.accent
                        : const Color(0xFFFCA5A5),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (perDay != null)
                Text(
                  '≈ ${Formatters.money(perDay)} por día',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              const SizedBox(height: 16),
              _Breakdown(overview: overview),
              if (cap != null && summary.income.isPositive) ...[
                const SizedBox(height: 16),
                _TodayCap(
                  spent: cap.spentToday,
                  cap: cap.cap,
                  exceeded: cap.exceeded,
                ),
              ],
              if (_note() case final note?) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _note() {
    if (summary.income.isZero && overview.available.isZero) {
      return 'Registra tu sueldo el día que llegue (o cuadra con tu dinero '
          'real): sin eso, esto es solo una estimación.';
    }
    if (overview.extraordinaryIncome.isPositive) {
      return 'Incluye ${Formatters.money(overview.extraordinaryIncome)} '
          'extraordinarios (prima, bono…): no llegan cada mes. Mira el plan '
          'en Tu CFO.';
    }
    if (overview.shortfall != null) {
      return 'Lo reservado es más que lo que tienes. Pausa lo no esencial o '
          'baja el ahorro de este ciclo.';
    }
    return null;
  }
}

class _DaysLeft extends StatelessWidget {
  const new({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        switch (days) {
          0 => 'Ciclo cerrado',
          1 => 'Último día',
          _ => '$days días',
        },
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppTheme.accent, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Barra apilada: disponible = fijos + apartados + ahorro + libre.
class _Breakdown extends StatelessWidget {
  const new({required this.overview});

  final MoneyOverview overview;

  static const _fixedColor = Color(0xFF7FB3A5);
  static const _provisionsColor = Color(0xFFE2C46B);
  static const _savingsColor = Color(0xFF6FA8DC);

  @override
  Widget build(BuildContext context) {
    final parts = <(String, Money, Color)>[
      ('Pagos fijos que faltan', overview.committed, _fixedColor),
      ('Pagos del año (apartar)', overview.provisionsPending, _provisionsColor),
      ('Ahorro del ciclo', overview.savingsPending, _savingsColor),
      ('Libre', overview.free.max(Money.zero), AppTheme.accent),
    ];
    final total = Money.sum(parts.map((p) => p.$2));
    final theme = Theme.of(context);
    const muted = Color(0xFFB9CBC4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tienes ',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            Text(
              Formatters.money(overview.available),
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFFF2F7F4),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (overview.expectedIncome.isPositive)
              Flexible(
                child: Text(
                  ' + ${Formatters.money(overview.expectedIncome)} por llegar',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(MoneyHeroCard._barHeight / 2),
          child: SizedBox(
            height: MoneyHeroCard._barHeight,
            child: total.isPositive
                ? Row(
                    children: [
                      for (final (_, amount, color) in parts)
                        if (amount.isPositive)
                          Expanded(
                            flex: (amount.cents * 1000 ~/ total.cents).clamp(
                              1,
                              1000,
                            ),
                            child: ColoredBox(color: color),
                          ),
                    ],
                  )
                : const ColoredBox(color: Color(0x33FFFFFF)),
          ),
        ),
        const SizedBox(height: 10),
        for (final (label, amount, color) in parts)
          if (amount.isPositive || label == 'Libre')
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                  Text(
                    Formatters.money(amount),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFF2F7F4),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _TodayCap extends StatelessWidget {
  const new({required this.spent, required this.cap, required this.exceeded});

  final Money spent;
  final Money cap;
  final bool exceeded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = cap - spent;
    final fraction = cap.isPositive
        ? (spent.cents / cap.cents).clamp(0.0, 1.0)
        : (exceeded ? 1.0 : 0.0);
    final color = exceeded ? const Color(0xFFFCA5A5) : AppTheme.accent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                exceeded ? Icons.do_not_disturb_on_outlined : Icons.today,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exceeded
                      ? 'Hoy pasaste tu tope por '
                            '${Formatters.money(remaining.abs)}'
                      : 'Hoy puedes gastar ${Formatters.money(remaining)} más',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFFF2F7F4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            color: color,
            backgroundColor: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(3),
            semanticsLabel: 'Tope de hoy usado',
          ),
          const SizedBox(height: 6),
          Text(
            'Tope del día ${Formatters.money(cap)} · llevas '
            '${Formatters.money(spent)} (almuerzos, transporte, antojos)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFFB9CBC4),
            ),
          ),
        ],
      ),
    );
  }
}
