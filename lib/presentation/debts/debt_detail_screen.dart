import 'package:finance_app/application/debts/debt_overview.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/loan_projector.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/labels.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
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
    final recordedRemaining = terms?.recordedRemainingInstallments;

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
              _Row('Cuotas restantes', '${projection.months}'),
              if (recordedRemaining != null &&
                  recordedRemaining != projection.months)
                Text(
                  'Según tu registro te faltan $recordedRemaining cuotas; la '
                  'proyección usa el saldo y la tasa actuales.',
                  style: theme.textTheme.bodySmall,
                ),
              _Row(
                'Fecha estimada de pago',
                Formatters.month(projection.payoffMonth!),
              ),
              _Row(
                'Intereses estimados',
                Formatters.money(projection.totalInterest),
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
