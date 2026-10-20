import 'package:finance_app/application/cashflow/cashflow_statement.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tu tablero de *Cashflow* (Padre Rico, Padre Pobre): estado de
/// resultados, balance, cuánto falta para salir de la carrera de la rata y
/// un juego de cartas para ver qué pasa si compras un activo o un capricho.
class CashflowScreen extends ConsumerWidget {
  const new({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const CashflowScreen()));

  static const _spacing = SizedBox(height: 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu Cashflow')),
      body: AsyncView(
        value: ref.watch(cashflowStatementProvider),
        builder: (s) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
          children: [
            _RatRaceCard(statement: s),
            _spacing,
            _IncomeStatementCard(statement: s),
            _spacing,
            _BalanceSheetCard(statement: s),
            _spacing,
            _GameCard(statement: s),
            _spacing,
            const _LessonsCard(),
            _spacing,
            Text(
              'Inspirado en Padre Rico, Padre Pobre y el juego Cashflow de '
              'Robert Kiyosaki. Calculado con tus datos: es una simulación '
              'educativa, no asesoría financiera.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Acceso desde Tu CFO: tu avance para salir de la carrera de la rata.
class CashflowEntryCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statement = ref.watch(cashflowStatementProvider).value;
    final freedom = statement?.freedom;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => CashflowScreen.open(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.casino_outlined, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu Cashflow', style: theme.textTheme.titleMedium),
                    Text(
                      statement == null
                          ? 'Padre Rico: activos, pasivos y la carrera de la '
                                'rata'
                          : 'Flujo del mes '
                                '${Formatters.money(statement.cashflow)} · '
                                'tus activos pagan '
                                '${freedom?.value.round() ?? 0}% de tus '
                                'gastos',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (freedom != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: freedom.fraction.clamp(0.0, 1.0),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                        semanticsLabel:
                            'Avance para salir de la carrera de la rata',
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cuánto de tus gastos ya pagan tus activos.
class _RatRaceCard extends StatelessWidget {
  const new({required this.statement});

  final CashflowStatement statement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const text = Color(0xFFF2F7F4);
    const muted = Color(0xFFB9CBC4);
    final s = statement;
    final freedom = s.freedom;
    final fraction = (freedom?.fraction ?? 0).clamp(0.0, 1.0);
    final percent = freedom == null ? '—' : '${freedom.value.round()}%';
    final message = switch (s) {
      _ when s.outOfRatRace =>
        '¡Saliste de la carrera de la rata! Tus activos pagan todos tus '
            'gastos: ya no dependes del sueldo.',
      _ when !s.passiveIncome.isPositive =>
        'Aún ningún activo te paga cada mes. En Patrimonio, escribe cuánto '
            'te produce cada bien (arriendo, utilidades) y lo verás aquí.',
      _ =>
        'Tus activos te pagan ${Formatters.money(s.passiveIncome)} al mes. '
            'Te faltan ${Formatters.money(s.passiveGap)} al mes de ingreso '
            'pasivo para no depender del sueldo.',
    };
    return Semantics(
      container: true,
      label:
          'Ingreso pasivo cubre $percent de tus gastos. '
          'Flujo de caja del mes ${Formatters.money(s.cashflow)}.',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainerHighest
              : AppTheme.forest,
          borderRadius: BorderRadius.circular(28),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: text),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salida de la carrera de la rata',
                style: theme.textTheme.titleSmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 4),
              Text(
                percent,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accent,
                ),
              ),
              Text(
                'de tus gastos lo pagan tus activos',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: fraction,
                minHeight: 10,
                color: AppTheme.accent,
                backgroundColor: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(5),
                semanticsLabel: 'Avance para salir de la carrera de la rata',
              ),
              const SizedBox(height: 12),
              Text(message, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text(
                'Flujo de caja del mes: '
                '${s.cashflow.isNegative ? '−' : '+'}'
                '${Formatters.money(s.cashflow.abs)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: s.cashflow.isNegative
                      ? const Color(0xFFFCA5A5)
                      : AppTheme.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ingresos − gastos = flujo de caja (la hoja del jugador).
class _IncomeStatementCard extends StatelessWidget {
  const new({required this.statement});

  final CashflowStatement statement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = statement;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SectionCard(
      title: 'Estado de resultados (al mes)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.isEstimate
                ? 'Estimado con este ciclo y tus fijos: aún no hay un ciclo '
                      'cerrado.'
                : 'Promedio de tus últimos ${s.cyclesUsed} '
                      '${s.cyclesUsed == 1 ? 'ciclo' : 'ciclos'}. Sin primas '
                      'ni ingresos extraordinarios.',
            style: muted,
          ),
          const SizedBox(height: 8),
          _Row('Sueldo (trabajas por él)', s.salary),
          if (s.otherIncome.isPositive) _Row('Otros ingresos', s.otherIncome),
          _Row('Ingreso pasivo (te pagan tus activos)', s.passiveIncome),
          const Divider(),
          _Row('Gastos', -s.expenses),
          if (s.debtPayments.isPositive)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Incluye ${Formatters.money(s.debtPayments)} en cuotas de '
                'deudas.',
                style: muted,
              ),
            ),
          const Divider(),
          _Row('Flujo de caja', s.cashflow, bold: true),
        ],
      ),
    );
  }
}

/// Activos (te pagan) vs. lo que te saca dinero.
class _BalanceSheetCard extends StatelessWidget {
  const new({required this.statement});

  final CashflowStatement statement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = statement;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final drains = [...s.costlyAssets, ...s.liabilities];
    return SectionCard(
      title: 'Balance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Un activo pone dinero en tu bolsillo; un pasivo lo saca.',
            style: muted,
          ),
          const SizedBox(height: 12),
          Text('Activos', style: theme.textTheme.titleSmall),
          for (final a in s.incomeAssets) _ItemRow(item: a),
          for (final i in s.investments) _ItemRow(item: i),
          if (s.savings.isPositive)
            _ItemRow(
              item: CashflowItem(
                name: 'Ahorros y cuentas',
                value: s.savings,
                monthly: Money.zero,
              ),
            ),
          if (s.incomeAssets.isEmpty &&
              s.investments.isEmpty &&
              !s.savings.isPositive)
            Text('Ninguno todavía.', style: muted),
          const SizedBox(height: 12),
          Text('Te sacan dinero cada mes', style: theme.textTheme.titleSmall),
          for (final d in drains) _ItemRow(item: d),
          if (drains.isEmpty) Text('Nada: bien hecho.', style: muted),
          if (s.costlyAssets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Tu carro o tu casa tienen valor, pero si no te producen y te '
                'cuestan cada mes, para Padre Rico son pasivos.',
                style: muted,
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const new({required this.item});

  final CashflowItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthly = item.monthly;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            monthly.isNegative
                ? Icons.south_west
                : monthly.isPositive
                ? Icons.north_east
                : Icons.savings_outlined,
            size: 18,
            color: monthly.isNegative
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(item.name)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Formatters.money(item.value)),
              if (!monthly.isZero)
                Text(
                  '${monthly.isNegative ? '−' : '+'}'
                  '${Formatters.money(monthly.abs)}/mes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: monthly.isNegative
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const new(this.label, this.amount, {this.bold = false});

  final String label;
  final Money amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = bold
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            '${amount.isNegative ? '−' : ''}${Formatters.money(amount.abs)}',
            style: style?.copyWith(
              color: bold && amount.isNegative ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Juega una carta: escribe un activo o un capricho y mira cómo cambia tu
/// tablero. No registra nada.
class _GameCard extends StatefulWidget {
  const new({required this.statement});

  final CashflowStatement statement;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  var _kind = CashflowCardKind.opportunity;
  final _upfront = TextEditingController();
  final _income = TextEditingController();
  final _cost = TextEditingController();

  @override
  void dispose() {
    _upfront.dispose();
    _income.dispose();
    _cost.dispose();
    super.dispose();
  }

  CashflowCard get _card => CashflowCard(
    kind: _kind,
    upfront: MoneyField.read(_upfront) ?? Money.zero,
    monthlyIncome: _kind == CashflowCardKind.opportunity
        ? MoneyField.read(_income) ?? Money.zero
        : Money.zero,
    monthlyCost: MoneyField.read(_cost) ?? Money.zero,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = _card;
    final played =
        card.upfront.isPositive ||
        card.monthlyIncome.isPositive ||
        card.monthlyCost.isPositive;
    final isDoodad = _kind == CashflowCardKind.doodad;
    void changed(String _) => setState(() {});
    return SectionCard(
      title: 'Juega una carta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDoodad
                ? 'Un capricho: celular, moto, viaje a cuotas… Mira cuánto te '
                      'aleja de la salida.'
                : 'Una oportunidad: un local, un parqueadero, un negocio… '
                      'algo que te pague cada mes.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<CashflowCardKind>(
              segments: const [
                ButtonSegment(
                  value: CashflowCardKind.opportunity,
                  icon: Icon(Icons.trending_up),
                  label: Text('Oportunidad'),
                ),
                ButtonSegment(
                  value: CashflowCardKind.doodad,
                  icon: Icon(Icons.shopping_bag_outlined),
                  label: Text('Capricho'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (v) => setState(() => _kind = v.first),
            ),
          ),
          const SizedBox(height: 12),
          MoneyField(
            controller: _upfront,
            label: isDoodad
                ? 'Cuota inicial o precio'
                : 'Lo que pagas de entrada',
            onChanged: changed,
          ),
          if (!isDoodad) ...[
            const SizedBox(height: 8),
            MoneyField(
              controller: _income,
              label: 'Te paga al mes',
              helperText: 'Arriendo, utilidades…',
              onChanged: changed,
            ),
          ],
          const SizedBox(height: 8),
          MoneyField(
            controller: _cost,
            label: 'Te cuesta al mes',
            helperText: 'Cuota del crédito, mantenimiento, administración…',
            onChanged: changed,
          ),
          if (played) ...[
            const SizedBox(height: 16),
            _Outcome(outcome: widget.statement.play(card), card: card),
          ],
        ],
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const new({required this.outcome, required this.card});

  final CashflowOutcome outcome;
  final CashflowCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = outcome.cashflowChange;
    final good = !change.isNegative;
    final color = good ? theme.colorScheme.primary : theme.colorScheme.error;
    String pct(CashflowStatement s) =>
        s.freedom == null ? '—' : '${s.freedom!.value.round()}%';
    String months(int n) => n == 1 ? '1 mes' : '$n meses';
    final payback = outcome.paybackMonths;
    final ofCashflow = outcome.monthsOfCashflow;
    final instead = Formatters.money(change.abs);
    final lines = [
      if (payback != null) 'Recuperas la entrada en ${months(payback)}.',
      if (card.kind == CashflowCardKind.opportunity &&
          !card.monthlyIncome.isPositive)
        'Si no te paga cada mes, no es un activo: es un gasto.',
      if (card.kind == CashflowCardKind.doodad && change.isNegative)
        'Con $instead al mes en un activo, avanzarías en vez de retroceder.',
      if (ofCashflow != null)
        'La entrada equivale a ${months(ofCashflow)} de tu flujo de caja.',
    ];
    return Semantics(
      container: true,
      label:
          'Flujo de caja pasa de ${Formatters.money(outcome.before.cashflow)} '
          'a ${Formatters.money(outcome.after.cashflow)}.',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  good ? Icons.thumb_up_alt_outlined : Icons.warning_amber,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    good
                        ? 'Tu flujo de caja sube '
                              '${Formatters.money(change)} al mes'
                        : 'Tu flujo de caja baja '
                              '${Formatters.money(change.abs)} al mes',
                    style: theme.textTheme.titleSmall?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Flujo de caja: ${Formatters.money(outcome.before.cashflow)} → '
              '${Formatters.money(outcome.after.cashflow)}',
            ),
            Text(
              'Salida de la carrera de la rata: ${pct(outcome.before)} → '
              '${pct(outcome.after)}',
            ),
            for (final line in lines) ...[
              const SizedBox(height: 4),
              Text(line, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonsCard extends StatelessWidget {
  const new();

  static const _lessons = [
    (
      'Activo vs. pasivo',
      'Un activo pone dinero en tu bolsillo cada mes; un pasivo lo saca. '
          'Compra activos primero; los lujos, con lo que ellos te paguen.',
    ),
    (
      'La carrera de la rata',
      'Ganar más y gastar más te deja en el mismo lugar. Se sale cuando lo '
          'que te pagan tus activos cubre tus gastos.',
    ),
    (
      'Págate primero',
      'Apenas llega el sueldo, aparta para comprar activos. Lo que sobra, se '
          'gasta; no al revés.',
    ),
    (
      'Los caprichos a cuotas',
      'Cada cuota es un gasto fijo nuevo que te aleja de la salida. Antes '
          'de comprarlo, juega la carta y mira cuánto te cuesta.',
    ),
    (
      'Tu flujo de caja manda',
      'No importa cuánto ganas sino cuánto te queda cada mes para poner a '
          'trabajar.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Lo que enseña Cashflow',
      child: Column(
        children: [
          for (final (title, detail) in _lessons)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(title),
              subtitle: Text(detail),
            ),
        ],
      ),
    );
  }
}
