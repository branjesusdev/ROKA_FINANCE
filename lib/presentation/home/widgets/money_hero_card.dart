import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/money_overview.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:finance_app/presentation/home/widgets/set_aside_sheet.dart';
import 'package:finance_app/presentation/home/widgets/today_spends_sheet.dart';
import 'package:finance_app/presentation/shared/decor.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/motion.dart';
import 'package:finance_app/presentation/transactions/spend_check_sheet.dart';
import 'package:flutter/material.dart';

/// Lo primero al abrir: cuánto puedes gastar de verdad (no el saldo), y de
/// dónde sale ese número. Responde "¿cuánto tengo?", "¿cuánto debo
/// reservar?" y "¿cuánto puedo gastar hoy?".
class MoneyHeroCard extends StatelessWidget {
  const new({
    required this.summary,
    required this.overview,
    this.salaryLate = false,
    super.key,
  });

  final CycleSummary summary;
  final MoneyOverview overview;

  /// Ya pasó el día de pago y el sueldo no se ha registrado: el ciclo
  /// anterior sigue abierto.
  final bool salaryLate;

  static const _barHeight = 12.0;
  static const _decorIntensity = 0.4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const text = AppTheme.onHero;
    const muted = AppTheme.onHeroMuted;
    // Lo que sobra del tope parejo no se ofrece para gastar: se aparta.
    final free = overview.free - overview.dayToDaySurplus;
    final shortfall = overview.shortfall;
    final perDay = overview.freePerDay;
    final cap = summary.dailyCap;

    return Semantics(
      container: true,
      label:
          'Libre para gastar ${Formatters.money(free)}. Disponible '
          '${Formatters.money(overview.available)}, reservado '
          '${Formatters.money(overview.reserved)}.',
      // Fondo distinto cada día; siempre oscuro para que todo se lea.
      child: DecorBackdrop.daily(
        DailyArt.forDay(summary.today),
        // Figuras tenues y en las esquinas: aquí manda leer los números.
        intensity: _decorIntensity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: text),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      switch ((shortfall, salaryLate)) {
                        (null, true) => 'Libre mientras llega tu sueldo',
                        (null, false) => 'Libre para gastar hasta tu sueldo',
                        _ => 'Te falta para cubrir lo reservado',
                      },
                      style: theme.textTheme.titleSmall?.copyWith(color: muted),
                    ),
                  ),
                  _DaysLeft(days: summary.daysLeft, salaryLate: salaryLate),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                // Cuenta hasta el valor: se nota cuando cambia.
                child: AnimatedMoneyText(
                  amount: shortfall ?? free,
                  format: Formatters.money,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: shortfall == null
                        ? AppTheme.accent
                        : const Color(0xFFFCA5A5),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (perDay != null && cap == null)
                Text(
                  '≈ ${Formatters.money(perDay)} por día',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              const SizedBox(height: 16),
              _Breakdown(overview: overview),
              if (overview.provisionsSaved.isPositive ||
                  overview.provisionsToday != null) ...[
                const SizedBox(height: 8),
                _SetAsideLine(overview: overview),
              ],
              if (cap != null && summary.income.isPositive) ...[
                const SizedBox(height: 16),
                _TodayCap(
                  spent: cap.spentToday,
                  cap: cap.cap,
                  exceeded: cap.exceeded,
                  outsideCap: summary.spentTodayOutsideCap,
                  onTap: summary.todaySpends.isEmpty
                      ? null
                      : () => showTodaySpendsSheet(context, summary: summary),
                ),
                if (cap.surplus.isPositive) ...[
                  const SizedBox(height: 8),
                  _SurplusLine(surplus: cap.surplus),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                    ),
                    onPressed: () => showSpendCheckSheet(context),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('¿Puedo gastar…?'),
                  ),
                ),
              ],
              if (overview.free.isPositive ||
                  overview.provisionsPending.isPositive) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: AppTheme.ink,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.savings_outlined),
                    label: Text(
                      (cap?.surplus.isPositive ?? false)
                          ? 'Apartar lo que sobra '
                                '(${Formatters.money(cap!.surplus)})'
                          : 'Apartar para no gastarlo',
                    ),
                    onPressed: () => showSetAsideSheet(context),
                  ),
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
    if (salaryLate) {
      return 'Tu sueldo aún no está registrado: sigues con el saldo del '
          'ciclo anterior. El ciclo nuevo empieza el día que lo anotes.';
    }
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
  const new({required this.days, required this.salaryLate});

  final int days;
  final bool salaryLate;

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
          _ when salaryLate => 'Esperando sueldo',
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

  static const _fixedColor = AppTheme.sky;
  static const _provisionsColor = AppTheme.orange;

  static const _savingsColor = AppTheme.blue;
  static const _plannedColor = AppTheme.mint;

  @override
  Widget build(BuildContext context) {
    final parts = <(String, Money, Color)>[
      ('Pagos fijos que faltan', overview.committed, _fixedColor),
      ('Pagos del año (apartar)', overview.provisionsPending, _provisionsColor),
      ('Ahorro del ciclo', overview.savingsPending, _savingsColor),
      (
        'Presupuesto del mes por gastar',
        overview.plannedPending,
        _plannedColor,
      ),
      ('Sobra: apártalo', overview.dayToDaySurplus, AppTheme.sun),
      (
        'Libre',
        (overview.free - overview.dayToDaySurplus).max(Money.zero),
        AppTheme.accent,
      ),
    ];
    final total = Money.sum(parts.map((p) => p.$2));
    final theme = Theme.of(context);
    const muted = AppTheme.onHeroMuted;
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
                color: AppTheme.onHero,
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
                ? ChartReveal(
                    replayKey: Object.hashAll(parts.map((p) => p.$2.cents)),
                    // La barra se llena de izquierda a derecha.
                    builder: (context, progress) => ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Row(
                          children: [
                            for (final (_, amount, color) in parts)
                              if (amount.isPositive)
                                Expanded(
                                  flex: (amount.cents * 1000 ~/ total.cents)
                                      .clamp(1, 1000),
                                  child: ColoredBox(color: color),
                                ),
                          ],
                        ),
                      ),
                    ),
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
                      color: AppTheme.onHero,
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

/// Lo que no cabe en el tope parejo del ciclo: no se gasta, se aparta.
class _SurplusLine extends StatelessWidget {
  const new({required this.surplus});

  final Money surplus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.sun.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.savings_outlined, size: 18, color: AppTheme.sun),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Te sobran ${Formatters.money(surplus)} del día a día: el tope '
              'reparte parejo todo el ciclo, no te deja gastarlo de golpe. '
              'Apártalo para pagos del año o tu meta.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onHero),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que ya está guardado para pagos del año y lo que toca apartar hoy.
class _SetAsideLine extends StatelessWidget {
  const new({required this.overview});

  final MoneyOverview overview;

  @override
  Widget build(BuildContext context) {
    const muted = AppTheme.onHeroMuted;
    final today = overview.provisionsToday;
    final saved = Formatters.money(overview.provisionsSaved);
    final parts = [
      if (overview.provisionsSaved.isPositive)
        'Ya apartado para pagos del año: $saved (no está en "Tienes")',
      if (today != null) 'Hoy aparta ${Formatters.money(today)}',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, size: 16, color: muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

class _TodayCap extends StatelessWidget {
  const new({
    required this.spent,
    required this.cap,
    required this.exceeded,
    required this.outsideCap,
    required this.onTap,
  });

  final Money spent;
  final Money cap;
  final bool exceeded;

  /// Gastado hoy en fijos, gastos del mes o ahorro (no baja el tope).
  final Money outsideCap;

  /// Abre el detalle de los gastos de hoy (`null` si no hay).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = cap - spent;
    final fraction = cap.isPositive
        ? (spent.cents / cap.cents).clamp(0.0, 1.0)
        : (exceeded ? 1.0 : 0.0);
    final color = exceeded ? const Color(0xFFFCA5A5) : AppTheme.accent;
    const muted = AppTheme.onHeroMuted;
    return Material(
      color: const Color(0x14FFFFFF),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _content(context, theme, remaining, fraction, color, muted),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ThemeData theme,
    Money remaining,
    double fraction,
    Color color,
    Color muted,
  ) => Column(
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
                color: AppTheme.onHero,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction),
        duration: Motion.enabled(context) ? Motion.slow : Duration.zero,
        curve: Motion.emphasized,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 6,
          color: color,
          backgroundColor: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(3),
          semanticsLabel: 'Tope de hoy usado',
        ),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: Text(
              [
                'Tope ${Formatters.money(cap)}',
                'día a día ${Formatters.money(spent)}',
                if (outsideCap.isPositive)
                  'fuera del tope ${Formatters.money(outsideCap)}',
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right, size: 18, color: muted),
        ],
      ),
    ],
  );
}
