import 'package:finance_app/application/debts/debt_overview.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/loan_projector.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/labels.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:finance_app/presentation/wealth/wealth_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Detalle de un crédito: proyección, pagos y simulador de abonos.
class DebtDetailScreen extends ConsumerStatefulWidget {
  const new({required this.debtId, super.key});

  final String debtId;

  @override
  ConsumerState<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends ConsumerState<DebtDetailScreen> {
  static const _quickExtras = [100000, 200000, 500000];

  final _extra = TextEditingController();

  @override
  void dispose() {
    _extra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(debtsProvider).value ?? const <Debt>[];
    final debt = debts.where((d) => d.id == widget.debtId).firstOrNull;
    if (debt == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final overview = DebtOverview.build(
      debt: debt,
      currentMonth: ref.watch(currentMonthProvider),
      extraMonthly: MoneyField.read(_extra) ?? Money.zero,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(debt.name),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                showFormSheet<void>(context, DebtFormSheet(debt: debt)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SummaryCard(overview: overview),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: debt.isPaidOff ? null : () => _pay(debt),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Pagar cuota'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: debt.isPaidOff ? null : () => _extraPayment(debt),
                  icon: const Icon(Icons.bolt),
                  label: const Text('Abono extra'),
                ),
              ),
            ],
          ),
          if (overview.interestCost case final cost?) ...[
            const SizedBox(height: 12),
            _InterestCostCard(overview: overview, cost: cost),
          ],
          if (overview.schedule.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ScheduleCard(overview: overview),
          ],
          if (overview.hasTerms && !debt.isPaidOff) ...[
            const SizedBox(height: 12),
            _AutoPayCard(debt: debt),
          ],
          if (overview.hasTerms && !debt.isPaidOff) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: '¿Qué pasa si pago más cada mes?',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MoneyField(
                    controller: _extra,
                    label: 'Pago adicional mensual',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final pesos in _quickExtras)
                        ActionChip(
                          label: Text(
                            '+${Formatters.money(Money.pesos(pesos))}',
                          ),
                          onPressed: () => setState(
                            () => _extra.text = Formatters.pesos(pesos),
                          ),
                        ),
                    ],
                  ),
                  if (overview.simulation case final simulation?) ...[
                    const SizedBox(height: 12),
                    _SimulationResult(comparison: simulation),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Es una simulación: no modifica tu crédito.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _ExtraPaymentsCard(debtId: debt.id),
        ],
      ),
    );
  }

  Future<void> _pay(Debt debt) => _askAmount(
    title: 'Pagar cuota de ${debt.name}',
    initial: debt.terms?.monthlyPayment,
    helper:
        'Se registra como gasto en "Deudas" y baja el saldo en la parte '
        'que abona a capital.',
    submit: (amount) =>
        ref.read(registerDebtPaymentProvider)(debt: debt, amount: amount),
    success: 'Pago registrado',
  );

  Future<void> _extraPayment(Debt debt) => _askAmount(
    title: 'Abono extraordinario',
    helper: 'Va 100% a capital y se registra como gasto en "Deudas".',
    submit: (amount) =>
        ref.read(registerExtraPaymentProvider)(debt: debt, amount: amount),
    success: 'Abono registrado',
    onDone: () => ref.invalidate(extraPaymentsProvider(debt.id)),
  );

  Future<void> _askAmount({
    required String title,
    required String helper,
    required Future<Result<Object?>> Function(Money amount) submit,
    required String success,
    Money? initial,
    VoidCallback? onDone,
  }) => showFormSheet<void>(
    context,
    _AmountSheet(
      title: title,
      helper: helper,
      initial: initial,
      submit: submit,
      success: success,
      onDone: onDone,
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const new({required this.overview});

  final DebtOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final debt = overview.debt;
    final terms = debt.terms;
    final projection = overview.projection;
    final paid = Percentage.ratio(debt.paidAmount, debt.originalAmount);

    return SectionCard(
      title: Labels.debt(debt.type),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row('Saldo actual', Formatters.money(debt.currentBalance)),
          _Row('Valor inicial', Formatters.money(debt.originalAmount)),
          if (paid != null) _Row('Pagado', Formatters.percent(paid)),
          if (terms != null) ...[
            _Row('Cuota mensual', Formatters.money(terms.monthlyPayment)),
            _Row(
              'Tasa',
              '${Formatters.percent(terms.rate.rate)} '
                  '${Labels.rateType(terms.rate.type)} '
                  '(≈ ${_monthlyRate(terms.rate.monthlyEffective)} mensual)',
            ),
            if (terms.monthlyFees.isPositive)
              _Row('Seguros/comisiones', Formatters.money(terms.monthlyFees)),
          ],
          if (projection != null) ...[
            const Divider(height: 24),
            if (!projection.isPayable)
              Text(
                'Con la cuota actual el saldo no baja: la cuota no alcanza '
                'a cubrir los intereses del mes.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            else ...[
              Text(
                'Según tu saldo, tasa y cuota',
                style: theme.textTheme.titleSmall,
              ),
              _Row('Cuotas que faltan', '${projection.months}'),
              _Row('Terminarías en', Formatters.month(projection.payoffMonth!)),
              if (overview.projectedTotal case final total?)
                _Row('Total por pagar', Formatters.money(total)),
              _Row(
                '  de eso, intereses',
                Formatters.money(projection.totalInterest),
              ),
              if (projection.totalFees.isPositive)
                _Row(
                  '  de eso, seguros/comisiones',
                  Formatters.money(projection.totalFees),
                ),
              if (overview.recorded case final recorded?) ...[
                const SizedBox(height: 12),
                Text(
                  'Según tu registro (${recorded.months} cuotas)',
                  style: theme.textTheme.titleSmall,
                ),
                _Row('Total por pagar', Formatters.money(recorded.totalToPay)),
                _Row(
                  '  de eso, intereses',
                  Formatters.money(recorded.interest),
                ),
                if (recorded.fees.isPositive)
                  _Row(
                    '  de eso, seguros/comisiones',
                    Formatters.money(recorded.fees),
                  ),
                if (overview.scheduleMismatch)
                  _MismatchNote(overview: overview, recorded: recorded),
              ],
              const SizedBox(height: 8),
              Text(
                'Intereses = lo que pagas de más sobre el saldo de hoy (no '
                'sobre el valor inicial). Lo que ya pagaste no cuenta.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Agrega la tasa y la cuota (Editar) para ver cuántas cuotas '
                'te faltan y simular abonos.',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// La cuota como gasto fijo: se registra sola cada mes, baja el saldo y
/// avisa cuántas cuotas faltan.
class _AutoPayCard extends ConsumerWidget {
  const new({required this.debt});

  final Debt debt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fixed = ref.watch(fixedMovementsProvider).value ?? const [];
    final linked = fixed.where((f) => f.debtId == debt.id).firstOrNull;
    final candidates = fixed
        .where(
          (f) =>
              f.isExpense &&
              f.debtId == null &&
              f.categoryId == DefaultCategories.debtsId,
        )
        .toList();
    return SectionCard(
      title: 'Cuota como gasto fijo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (linked != null) ...[
            Row(
              children: [
                Icon(
                  Icons.link,
                  size: 18,
                  color: StatusColors.okOf(theme.colorScheme),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Enlazado con «${linked.name}» (día ${linked.dayOfMonth}, '
                    '${Formatters.money(linked.amount)}).',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Cada mes se registra sola, baja el saldo y suma la cuota '
              'pagada. Te avisa la víspera cuántas cuotas te quedan. No uses '
              '"Pagar cuota" o se contaría dos veces.',
              style: theme.textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.link_off),
                label: const Text('Quitar enlace'),
                onPressed: () async {
                  final result = await ref
                      .read(linkDebtToFixedProvider)
                      .unlink(linked);
                  if (context.mounted) showResult(context, result);
                },
              ),
            ),
          ] else ...[
            Text(
              'Enlázala con tus gastos fijos: cada mes se registra sola, '
              'baja el saldo y te avisa cuántas cuotas y cuánto te falta.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            for (final f in candidates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_repeat),
                title: Text(f.name),
                subtitle: Text(
                  'Día ${f.dayOfMonth} · ${Formatters.money(f.amount)}',
                ),
                trailing: const Text('Enlazar'),
                onTap: () async {
                  final result = await ref
                      .read(linkDebtToFixedProvider)
                      .call(debt: debt, fixed: f);
                  if (context.mounted) {
                    showResult(context, result, success: 'Cuota enlazada');
                  }
                },
              ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add),
              label: Text(
                'Crear fijo de '
                '${Formatters.money(debt.terms!.monthlyPayment)} al mes',
              ),
              onPressed: () => _create(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final day = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('¿Qué día pagas la cuota?'),
        children: [
          SizedBox(
            width: double.maxFinite,
            height: 320,
            child: GridView.count(
              crossAxisCount: 7,
              padding: const EdgeInsets.all(8),
              children: [
                for (
                  var d = FixedMovement.minDay;
                  d <= FixedMovement.maxDay;
                  d++
                )
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(d),
                    child: Text('$d'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (day == null || !context.mounted) return;
    final result = await ref
        .read(linkDebtToFixedProvider)
        .call(debt: debt, dayOfMonth: day);
    if (context.mounted) {
      showResult(context, result, success: 'Fijo creado y enlazado');
    }
  }
}

/// Tu registro y el cálculo no dan las mismas cuotas: menos cuotas que el
/// plan = vas adelantado (abonos); más = vas atrasado y toca revisar.
class _MismatchNote extends StatelessWidget {
  const new({required this.overview, required this.recorded});

  final DebtOverview overview;
  final RecordedSchedule recorded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projection = overview.projection!;
    final terms = overview.debt.terms!;
    final diff = (recorded.months - projection.months).abs();
    final implied = recorded.impliedAnnualRate;
    final ahead = recorded.months > projection.months;
    final color = ahead
        ? StatusColors.okOf(theme.colorScheme)
        : StatusColors.warningOf(theme.colorScheme);
    final cuotas = diff == 1 ? 'cuota' : 'cuotas';
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ahead ? Icons.emoji_events_outlined : Icons.warning_amber,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ahead
                        ? '¡Excelente! Vas $diff $cuotas adelantado'
                        : 'Ojo: vas $diff $cuotas atrasado',
                    style: theme.textTheme.titleSmall?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              ahead
                  ? 'Con tus abonos terminas en ${projection.months} cuotas '
                        'y no en ${recorded.months}.'
                  : 'Con este saldo faltarían ${projection.months} cuotas y '
                        'tu plan dice ${recorded.months}. Revisa en Editar '
                        'el saldo, la tasa y los seguros del extracto.',
              style: theme.textTheme.bodySmall,
            ),
            if (!ahead && implied != null) ...[
              const SizedBox(height: 4),
              Text(
                'Tasa que daría tu plan ≈ ${_annual(implied)} EA · '
                'anotaste ${_annual(terms.rate.annualEffective)} EA.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _annual(double fraction) =>
      Formatters.percent(Percentage.fromFraction(fraction));
}

/// Intereses del crédito completo: ya pagados + los que faltan, frente al
/// plan sin abonos.
class _InterestCostCard extends StatelessWidget {
  const new({required this.overview, required this.cost});

  final DebtOverview overview;
  final LoanInterestCost cost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = cost.savedVsPlan;
    final ahead = overview.installmentsAhead;
    final good = [
      if (ahead > 0) 'Vas $ahead ${ahead == 1 ? 'cuota' : 'cuotas'} adelantado',
      if (saved.isPositive)
        'te ahorras ≈ ${Formatters.money(saved)} en intereses frente al plan',
    ];
    return SectionCard(
      title: 'Lo que te cuesta en intereses',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row('Ya pagados (aprox.)', Formatters.money(cost.paidSoFar)),
          _Row('Faltan por pagar', Formatters.money(cost.remaining)),
          _Row('Total del crédito', Formatters.money(cost.total)),
          _Row('Plan sin abonos', Formatters.money(cost.plan)),
          if (good.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.savings_outlined,
                  size: 18,
                  color: StatusColors.okOf(theme.colorScheme),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${good.join(' y ')}.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Sin seguros. Los ya pagados se estiman con el plan desde el '
            'valor inicial: si abonaste de más, pagaste algo menos.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Tabla de pagos de las cuotas que faltan, como la proyección del banco.
class _ScheduleCard extends StatefulWidget {
  const new({required this.overview});

  final DebtOverview overview;

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  /// Filas visibles antes de "Ver todas".
  static const _preview = 6;

  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = widget.overview.schedule;
    final visible = _all ? rows : rows.take(_preview);
    final interest = Money.sum(rows.map((r) => r.interest));
    final principal = Money.sum(rows.map((r) => r.principal));
    return SectionCard(
      title: 'Tabla de pagos (${rows.length} cuotas)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in visible) _InstallmentTile(row: row),
          if (rows.length > _preview)
            TextButton(
              onPressed: () => setState(() => _all = !_all),
              child: Text(_all ? 'Ver menos' : 'Ver las ${rows.length} cuotas'),
            ),
          const Divider(height: 16),
          _Row('Suman a capital', Formatters.money(principal)),
          _Row('Suman intereses', Formatters.money(interest)),
          const SizedBox(height: 4),
          Text(
            'Cuota sin seguros. Supone que pagas a tiempo y la tasa no '
            'cambia; compárala con la proyección de tu banco.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const new({required this.row});

  final LoanInstallment row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = row.number;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${number == null ? '' : 'Cuota $number · '}'
                  '${Formatters.monthShort(row.month)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                Formatters.money(row.payment),
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          Text(
            'Capital ${Formatters.money(row.principal)} · intereses '
            '${Formatters.money(row.interest)} · queda '
            '${Formatters.money(row.balance)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _monthlyRate(double fraction) =>
    Formatters.percent(Percentage.fromFraction(fraction));

class _SimulationResult extends StatelessWidget {
  const new({required this.comparison});

  final LoanComparison comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = comparison.base;
    final extra = comparison.withExtra;
    final monthsSaved = comparison.monthsSaved;
    final interestSaved = comparison.interestSaved;

    String months(LoanProjection p) =>
        p.isPayable ? '${p.months} cuotas' : 'No termina';
    String end(LoanProjection p) =>
        p.isPayable ? Formatters.month(p.payoffMonth!) : '-';
    String interest(LoanProjection p) =>
        p.isPayable ? Formatters.money(p.totalInterest) : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(1.2)},
          children: [
            TableRow(
              children: [
                const SizedBox.shrink(),
                Text('Pago normal', style: theme.textTheme.labelLarge),
                Text('Con abono', style: theme.textTheme.labelLarge),
              ],
            ),
            for (final (label, value) in [
              ('Duración', months),
              ('Termina', end),
              ('Intereses', interest),
            ])
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(label, style: theme.textTheme.bodySmall),
                  ),
                  Text(value(base)),
                  Text(value(extra)),
                ],
              ),
          ],
        ),
        if (monthsSaved != null &&
            interestSaved != null &&
            monthsSaved > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Terminarías $monthsSaved '
              '${monthsSaved == 1 ? 'mes' : 'meses'} antes y pagarías '
              '${Formatters.money(interestSaved)} menos en intereses.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ExtraPaymentsCard extends ConsumerWidget {
  const new({required this.debtId});

  final String debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(extraPaymentsProvider(debtId)).value ?? const [];
    if (payments.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: 'Abonos extraordinarios',
      child: Column(
        children: [
          for (final p in payments)
            _Row(Formatters.shortDate(p.date), Formatters.money(p.amount)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const new(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountSheet extends StatefulWidget {
  const new({
    required this.title,
    required this.helper,
    required this.submit,
    required this.success,
    this.initial,
    this.onDone,
  });

  final String title;
  final String helper;
  final Future<Result<Object?>> Function(Money amount) submit;
  final String success;
  final Money? initial;
  final VoidCallback? onDone;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final _amount = TextEditingController(
    text: MoneyField.initial(widget.initial),
  );
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: widget.title,
      onSave: _saving ? null : _save,
      children: [
        MoneyField(
          controller: _amount,
          label: 'Valor',
          helperText: widget.helper,
          autofocus: true,
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await widget.submit(MoneyField.read(_amount) ?? Money.zero);
    if (!mounted) return;
    if (showResult(context, result, success: widget.success)) {
      widget.onDone?.call();
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }
}
