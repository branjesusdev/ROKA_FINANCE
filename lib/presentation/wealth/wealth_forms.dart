import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Activo nuevo ([asset] = null) o edición.
class AssetFormSheet extends ConsumerStatefulWidget {
  const new({this.asset, super.key});

  final Asset? asset;

  @override
  ConsumerState<AssetFormSheet> createState() => _AssetFormSheetState();
}

class _AssetFormSheetState extends ConsumerState<AssetFormSheet> {
  late final _name = TextEditingController(text: widget.asset?.name);
  late final _value = TextEditingController(
    text: MoneyField.initial(widget.asset?.currentValue),
  );
  late final _notes = TextEditingController(text: widget.asset?.notes);
  late AssetType _type = widget.asset?.type ?? AssetType.bankAccount;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    return FormSheet(
      title: asset == null ? 'Nuevo activo' : 'Editar activo',
      onSave: _save,
      extraActions: [
        if (asset != null)
          TextButton(
            onPressed: () async {
              if (!await confirmDelete(context, 'este activo')) return;
              final result = await ref.read(deleteAssetProvider)(asset.id);
              if (!context.mounted) return;
              if (showResult(context, result)) Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
      ],
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in AssetType.values)
              ChoiceChip(
                avatar: Icon(Labels.assetIcon(type), size: 18),
                label: Text(Labels.asset(type)),
                selected: type == _type,
                onSelected: (_) => setState(() => _type = type),
              ),
          ],
        ),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Cuenta de ahorros',
            border: OutlineInputBorder(),
          ),
        ),
        MoneyField(controller: _value, label: 'Valor actual'),
        TextField(
          controller: _notes,
          decoration: const InputDecoration(
            labelText: 'Notas (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final result = await ref
        .read(saveAssetProvider)
        .call(
          id: widget.asset?.id,
          name: _name.text,
          type: _type,
          value: MoneyField.read(_value) ?? Money.zero,
          notes: _notes.text,
        );
    if (mounted && showResult(context, result, success: 'Activo guardado')) {
      Navigator.pop(context);
    }
  }
}

class InvestmentFormSheet extends ConsumerStatefulWidget {
  const new({this.investment, super.key});

  final Investment? investment;

  @override
  ConsumerState<InvestmentFormSheet> createState() =>
      _InvestmentFormSheetState();
}

class _InvestmentFormSheetState extends ConsumerState<InvestmentFormSheet> {
  late final _name = TextEditingController(text: widget.investment?.name);
  late final _invested = TextEditingController(
    text: MoneyField.initial(widget.investment?.investedAmount),
  );
  late final _current = TextEditingController(
    text: MoneyField.initial(widget.investment?.currentValue),
  );
  late InvestmentType _type = widget.investment?.type ?? InvestmentType.fund;
  late DateTime? _date = widget.investment?.date;

  @override
  void dispose() {
    _name.dispose();
    _invested.dispose();
    _current.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final investment = widget.investment;
    return FormSheet(
      title: investment == null ? 'Nueva inversión' : 'Editar inversión',
      onSave: _save,
      extraActions: [
        if (investment != null)
          TextButton(
            onPressed: () async {
              if (!await confirmDelete(context, 'esta inversión')) return;
              final result = await ref.read(deleteInvestmentProvider)(
                investment.id,
              );
              if (!context.mounted) return;
              if (showResult(context, result)) Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
      ],
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in InvestmentType.values)
              ChoiceChip(
                label: Text(Labels.investment(type)),
                selected: type == _type,
                onSelected: (_) => setState(() => _type = type),
              ),
          ],
        ),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Fondo de inversión colectiva',
            border: OutlineInputBorder(),
          ),
        ),
        MoneyField(controller: _invested, label: 'Valor invertido'),
        MoneyField(
          controller: _current,
          label: 'Valor actual',
          helperText: 'Actualízalo cuando revises tu extracto.',
        ),
        DateTile(
          label: 'Fecha de inversión',
          value: _date,
          lastDate: DateTime.now(),
          onChanged: (date) => setState(() => _date = date),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final invested = MoneyField.read(_invested) ?? Money.zero;
    final result = await ref
        .read(saveInvestmentProvider)
        .call(
          id: widget.investment?.id,
          name: _name.text,
          type: _type,
          invested: invested,
          currentValue: MoneyField.read(_current) ?? invested,
          date: _date,
          notes: widget.investment?.notes,
        );
    if (mounted && showResult(context, result, success: 'Inversión guardada')) {
      Navigator.pop(context);
    }
  }
}

/// Deuda simple (solo saldo) o crédito con tasa y cuota.
class DebtFormSheet extends ConsumerStatefulWidget {
  const new({this.debt, super.key});

  final Debt? debt;

  @override
  ConsumerState<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends ConsumerState<DebtFormSheet> {
  late final Debt? _debt = widget.debt;
  late final LoanTerms? _terms = _debt?.terms;
  late final _name = TextEditingController(text: _debt?.name);
  late final _original = TextEditingController(
    text: MoneyField.initial(_debt?.originalAmount),
  );
  late final _balance = TextEditingController(
    text: MoneyField.initial(_debt?.currentBalance),
  );
  late final _rate = TextEditingController(
    text: PercentField.initial(_terms?.rate.rate),
  );
  late final _payment = TextEditingController(
    text: MoneyField.initial(_terms?.monthlyPayment),
  );
  late final _fees = TextEditingController(
    text: MoneyField.initial(_terms?.monthlyFees),
  );
  late final _total = TextEditingController(
    text: _terms?.totalInstallments?.toString(),
  );
  late final _paid = TextEditingController(
    text: _terms?.paidInstallments?.toString(),
  );
  late final _notes = TextEditingController(text: _debt?.notes);
  late DebtType _type = _debt?.type ?? DebtType.bankLoan;
  late bool _hasTerms = _debt == null || _terms != null;
  late InterestRateType _rateType =
      _terms?.rate.type ?? InterestRateType.effectiveAnnual;
  late DateTime? _startDate = _terms?.startDate;

  @override
  void dispose() {
    for (final c in [
      _name,
      _original,
      _balance,
      _rate,
      _payment,
      _fees,
      _total,
      _paid,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debt = _debt;
    return FormSheet(
      title: debt == null ? 'Nueva deuda o crédito' : 'Editar deuda',
      onSave: _save,
      extraActions: [
        if (debt != null)
          TextButton(
            onPressed: () async {
              if (!await confirmDelete(context, 'esta deuda')) return;
              final result = await ref.read(deleteDebtProvider)(debt.id);
              if (!context.mounted || !showResult(context, result)) return;
              Navigator.of(context)
                ..pop()
                ..maybePop();
            },
            child: const Text('Eliminar'),
          ),
      ],
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in DebtType.values)
              ChoiceChip(
                avatar: Icon(Labels.debtIcon(type), size: 18),
                label: Text(Labels.debt(type)),
                selected: type == _type,
                onSelected: (_) => setState(() => _type = type),
              ),
          ],
        ),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Crédito vehículo',
            border: OutlineInputBorder(),
          ),
        ),
        MoneyField(controller: _original, label: 'Valor inicial'),
        MoneyField(controller: _balance, label: 'Saldo actual'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Tiene tasa y cuota fija'),
          subtitle: const Text('Para ver cuotas restantes y simular abonos.'),
          value: _hasTerms,
          onChanged: (value) => setState(() => _hasTerms = value),
        ),
        if (_hasTerms) ...[
          Row(
            children: [
              Expanded(
                child: PercentField(controller: _rate, label: 'Tasa'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<InterestRateType>(
                  initialValue: _rateType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final type in InterestRateType.values)
                      DropdownMenuItem(
                        value: type,
                        child: Text(Labels.rateType(type)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _rateType = value!),
                ),
              ),
            ],
          ),
          MoneyField(
            controller: _payment,
            label: 'Cuota mensual',
            helperText: 'Lo que pagas cada mes, incluidos seguros.',
          ),
          MoneyField(
            controller: _fees,
            label: 'Seguros/comisiones incluidos en la cuota (opcional)',
          ),
          Row(
            children: [
              Expanded(
                child: IntegerField(
                  controller: _total,
                  label: 'Cuotas totales',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: IntegerField(controller: _paid, label: 'Cuotas pagadas'),
              ),
            ],
          ),
          DateTile(
            label: 'Fecha de inicio',
            value: _startDate,
            lastDate: DateTime.now(),
            onChanged: (date) => setState(() => _startDate = date),
          ),
        ],
        TextField(
          controller: _notes,
          decoration: const InputDecoration(
            labelText: 'Notas (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final rate = PercentField.read(_rate);
    final terms = _hasTerms
        ? LoanTerms(
            rate: InterestRate(rate: rate ?? Percentage.zero, type: _rateType),
            monthlyPayment: MoneyField.read(_payment) ?? Money.zero,
            monthlyFees: MoneyField.read(_fees) ?? Money.zero,
            totalInstallments: IntegerField.read(_total),
            paidInstallments: IntegerField.read(_paid),
            startDate: _startDate,
          )
        : null;
    final original = MoneyField.read(_original) ?? Money.zero;
    final result = await ref
        .read(saveDebtProvider)
        .call(
          id: _debt?.id,
          name: _name.text,
          type: _type,
          originalAmount: original,
          currentBalance: MoneyField.read(_balance) ?? original,
          terms: terms,
          notes: _notes.text,
        );
    if (mounted && showResult(context, result, success: 'Deuda guardada')) {
      Navigator.pop(context);
    }
  }
}
