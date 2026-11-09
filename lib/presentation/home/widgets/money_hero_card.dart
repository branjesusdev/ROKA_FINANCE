import 'package:finance_app/application/dashboard/cycle_ledger.dart';
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
/// reservar?", "¿voy bien?" y "¿cuánto puedo gastar hoy?".
///
/// Se adapta al tema: oscura con número en lima, o clara (papel blanco con
/// el brillo del día) con número en tinta. Colores en [HeroPalette].
class MoneyHeroCard extends StatelessWidget {
  const new({
    required this.summary,
    required this.overview,
    this.ledger = CycleLedger.empty,
    this.salaryLate = false,
    super.key,
  });

  final CycleSummary summary;
  final MoneyOverview overview;

  /// Lo que sobró de cada ciclo: para el dinero total.
  final CycleLedger ledger;

  /// Ya pasó el día de pago y el sueldo no se ha registrado: el ciclo
  /// anterior sigue abierto.
  final bool salaryLate;

  static const _barHeight = 12.0;
  static const _decorIntensity = 0.4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = HeroPalette.of(context);
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
      // Fondo distinto cada día, claro u oscuro según el tema.
      child: DecorBackdrop.daily(
        DailyArt.forDay(summary.today),
        // Figuras tenues y en las esquinas: aquí manda leer los números.
        intensity: _decorIntensity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: palette.text),
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.muted,
                      ),
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
                        ? palette.highlight
                        : palette.danger,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (perDay != null && cap == null)
                Text(
                  '≈ ${Formatters.money(perDay)} por día',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.muted,
                  ),
                ),
              const SizedBox(height: 12),
              _StatusLines(
                summary: summary,
                overview: overview,
                ledger: ledger,
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
                  whyZero: cap.cap.isZero ? _whyZero() : null,
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
                      foregroundColor: palette.isLight
                          ? palette.text
                          : AppTheme.accent,
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
                      backgroundColor: palette.isLight
                          ? AppTheme.ink
                          : AppTheme.accent,
                      foregroundColor: palette.isLight
                          ? Colors.white
                          : AppTheme.ink,
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
                    Icon(Icons.info_outline, size: 16, color: palette.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.muted,
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

  /// Por qué hoy no hay tope: lo que ya se llevó el dinero del ciclo.
  String _whyZero() {
    final parts = [
      if (overview.committed.isPositive)
        'fijos ${Formatters.money(overview.committed)}',
      if (overview.plannedPending.isPositive)
        'mercado y gastos del mes ${Formatters.money(overview.plannedPending)}',
      if (overview.provisionsPending.isPositive)
        'pagos del año ${Formatters.money(overview.provisionsPending)}',
      if (overview.savingsPending.isPositive)
        'ahorro ${Formatters.money(overview.savingsPending)}',
    ];
    if (parts.isEmpty) {
      return 'No queda dinero del ciclo para el día a día.';
    }
    return 'Tu dinero del ciclo ya está repartido en ${parts.join(', ')}. '
        'Baja el presupuesto o pausa algo para tener tope.';
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
    final palette = HeroPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.chip,
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
            ?.copyWith(color: palette.onChip, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Estado del ciclo en una mirada: ahorro (bien / falta / no alcanza) y el
/// dinero total con lo que sobró de los ciclos anteriores. Siempre icono +
/// color + texto.
class _StatusLines extends StatelessWidget {
  const new({
    required this.summary,
    required this.overview,
    required this.ledger,
  });

  final CycleSummary summary;
  final MoneyOverview overview;
  final CycleLedger ledger;

  @override
  Widget build(BuildContext context) {
    final palette = HeroPalette.of(context);
    final carried = ledger.carried;
    final lines = <(IconData, Color, String)>[
      if (summary.savingsTarget.isPositive)
        if (overview.shortfall != null)
          (
            Icons.error_outline,
            palette.danger,
            'Ahorro en riesgo: lo reservado no alcanza',
          )
        else if (overview.savingsPending.isPositive)
          (
            Icons.warning_amber_rounded,
            palette.warning,
            'Te falta apartar ${Formatters.money(overview.savingsPending)} '
                'para tu ahorro del ciclo',
          )
        else
          (
            Icons.check_circle_outline,
            palette.positive,
            (summary.previousLeft?.isPositive ?? false)
                ? 'Ahorro del ciclo cubierto con lo que te sobró'
                : 'Ahorro del ciclo cubierto',
          ),
      if (!ledger.isEmpty && !carried.isZero)
        (
          carried.isNegative ? Icons.trending_down : Icons.account_balance,
          carried.isNegative ? palette.danger : palette.positive,
          'Total ${Formatters.money(ledger.total)}: '
              '${carried.isNegative ? 'debes' : 'te sobró'} '
              '${Formatters.money(carried.abs)} de ciclos anteriores',
        ),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (icon, color, text) in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    style: style?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
    final palette = HeroPalette.of(context);
    final parts = <(String, Money, Color)>[
      ('Pagos fijos que faltan', overview.committed, _fixedColor),
      ('Pagos del año (apartar)', overview.provisionsPending, _provisionsColor),
      ('Ahorro del ciclo', overview.savingsPending, _savingsColor),
      (
        'Mercado y gastos del mes (presupuesto)',
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
    final muted = palette.muted;
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
                color: palette.text,
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
            child: ColoredBox(
              color: palette.track,
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
                  : const SizedBox.expand(),
            ),
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
                      // En claro el lima y el ámbar se pierden sobre blanco.
                      border: palette.isLight
                          ? Border.all(color: palette.track)
                          : null,
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
                      color: palette.text,
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
    final palette = HeroPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.sun.withValues(alpha: palette.isLight ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.savings_outlined,
            size: 18,
            color: palette.isLight ? palette.warning : AppTheme.sun,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Te sobran ${Formatters.money(surplus)} del día a día: el tope '
              'reparte parejo todo el ciclo, no te deja gastarlo de golpe. '
              'Apártalo para pagos del año o tu meta.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: palette.text),
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
    final muted = HeroPalette.of(context).muted;
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
        Icon(Icons.lock_outline, size: 16, color: muted),
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

/// Tope del día a día: lo que no es mercado, fijos, cuotas ni ahorro.
class _TodayCap extends StatelessWidget {
  const new({
    required this.spent,
    required this.cap,
    required this.exceeded,
    required this.outsideCap,
    required this.onTap,
    this.whyZero,
  });

  final Money spent;
  final Money cap;
  final bool exceeded;

  /// Gastado hoy en fijos, mercado y gastos del mes o ahorro (no baja el
  /// tope).
  final Money outsideCap;

  /// Explicación cuando el tope es cero (`null` si hay tope).
  final String? whyZero;

  /// Abre el detalle de los gastos de hoy (`null` si no hay).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = HeroPalette.of(context);
    final remaining = cap - spent;
    final fraction = cap.isPositive
        ? (spent.cents / cap.cents).clamp(0.0, 1.0)
        : (exceeded ? 1.0 : 0.0);
    final noCap = whyZero != null && !exceeded;
    final outside = Formatters.money(outsideCap);
    final color = exceeded
        ? palette.danger
        : noCap
        ? palette.warning
        : palette.positive;
    return Material(
      color: palette.panel,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    exceeded
                        ? Icons.do_not_disturb_on_outlined
                        : noCap
                        ? Icons.warning_amber_rounded
                        : Icons.today,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exceeded
                          ? 'Hoy pasaste tu tope por '
                                '${Formatters.money(remaining.abs)}'
                          : noCap
                          ? 'Hoy no tienes tope para el día a día'
                          : 'Hoy puedes gastar ${Formatters.money(remaining)} '
                                'más',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.text,
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
                  color: exceeded ? palette.danger : AppTheme.accent,
                  backgroundColor: palette.track,
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
                        'Tope del día a día ${Formatters.money(cap)}',
                        'gastado ${Formatters.money(spent)}',
                        if (outsideCap.isPositive)
                          'mercado, fijos y ahorro $outside (no cuentan)',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, size: 18, color: palette.muted),
                ],
              ),
              if (whyZero case final why? when noCap) ...[
                const SizedBox(height: 6),
                Text(
                  why,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.text,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
