import 'dart:async';

import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/usd_rate.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
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
  late final _cost = TextEditingController(
    text: _initialOrEmpty(widget.asset?.monthlyCost),
  );
  late final _income = TextEditingController(
    text: _initialOrEmpty(widget.asset?.monthlyIncome),
  );
  late AssetType _type = widget.asset?.type ?? AssetType.bankAccount;
  late Liquidity? _liquidity = widget.asset?.liquidity;
  late String? _debtId = widget.asset?.linkedDebtId;

  static String _initialOrEmpty(Money? money) =>
      money == null || money.isZero ? '' : MoneyField.initial(money);

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _notes.dispose();
    _cost.dispose();
    _income.dispose();
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
        MoneyField(
          controller: _value,
          label: 'Valor estimado hoy',
          helperText: 'Lo que te darían si lo vendieras hoy (sin la deuda).',
        ),
        MoneyField(
          controller: _cost,
          label: 'Cuánto te cuesta al mes (opcional)',
          helperText: 'Seguro, impuestos, mantenimiento, administración…',
        ),
        MoneyField(
          controller: _income,
          label: 'Cuánto te produce al mes (opcional)',
          helperText: 'Arriendo, utilidades, intereses…',
        ),
        DropdownButtonFormField<Liquidity?>(
          initialValue: _liquidity,
          decoration: const InputDecoration(
            labelText: '¿Qué tan rápido lo vuelves dinero?',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(child: Text('Según el tipo')),
            DropdownMenuItem(
              value: Liquidity.high,
              child: Text('Hoy mismo (alta)'),
            ),
            DropdownMenuItem(
              value: Liquidity.medium,
              child: Text('En semanas (media)'),
            ),
            DropdownMenuItem(
              value: Liquidity.low,
              child: Text('En meses (baja)'),
            ),
          ],
          onChanged: (value) => setState(() => _liquidity = value),
        ),
        if (ref.watch(debtsProvider).value case final debts?
            when debts.isNotEmpty)
          DropdownButtonFormField<String?>(
            initialValue: debts.any((d) => d.id == _debtId) ? _debtId : null,
            decoration: const InputDecoration(
              labelText: '¿Lo financiaste con un crédito? (opcional)',
              helperText:
                  'El saldo ya cuenta como deuda: no se resta dos veces.',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(child: Text('No')),
              for (final debt in debts)
                DropdownMenuItem(value: debt.id, child: Text(debt.name)),
            ],
            onChanged: (value) => setState(() => _debtId = value),
          ),
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
          monthlyCost: MoneyField.read(_cost) ?? Money.zero,
          monthlyIncome: MoneyField.read(_income) ?? Money.zero,
          liquidity: _liquidity,
          linkedDebtId: _debtId,
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
  late final _symbol = TextEditingController(text: widget.investment?.symbol);
  late final _units = TextEditingController(
    text: _unitsText(widget.investment?.units),
  );
  late InvestmentType _type = widget.investment?.type ?? InvestmentType.fund;
  late DateTime? _date = widget.investment?.date;

  /// Lo pagaste en dólares: se escribe en US$ y se pasa a pesos.
  late bool _inUsd = widget.investment?.investedUsdCents != null;
  late final _investedUsd = TextEditingController(
    text: UsdField.initial(widget.investment?.investedUsdCents),
  );
  late final _currentUsd = TextEditingController();
  late final _rate = TextEditingController(text: _initialRate());

  /// El dólar de hoy llegó de internet (para explicarlo en el campo).
  bool _rateFromMarket = false;
  bool _loadingRate = false;

  /// Dólar con el que se guardó (pesos invertidos / dólares invertidos).
  String _initialRate() {
    final investment = widget.investment;
    final usd = investment?.investedUsdCents;
    if (investment == null || usd == null || usd <= 0) return '';
    return Formatters.pesos((investment.investedAmount.cents / usd).round());
  }

  UsdRate? get _usdRate {
    final pesos = MoneyField.read(_rate);
    return pesos == null ? null : UsdRate(pesos);
  }

  /// Tipos que suelen tener precio público.
  static const _marketTypes = {
    InvestmentType.stocks,
    InvestmentType.fund,
    InvestmentType.crypto,
  };

  static String _unitsText(double? units) {
    if (units == null) return '';
    final text = units.toStringAsFixed(6);
    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '')
        .replaceAll('.', ',');
  }

  /// "2,5" o "2.5" → millonésimas. `null` si está vacío o no es número.
  static int? _readUnits(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) return null;
    return (value * Investment.microsPerUnit).round();
  }

  @override
  void dispose() {
    _name.dispose();
    _invested.dispose();
    _current.dispose();
    _symbol.dispose();
    _units.dispose();
    _investedUsd.dispose();
    _currentUsd.dispose();
    _rate.dispose();
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
        if (_marketTypes.contains(_type)) ...[
          TextField(
            controller: _symbol,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Símbolo en bolsa (opcional)',
              hintText: 'Ej: NVDA, VOO, BTC-USD',
              helperText:
                  'Con el símbolo y la cantidad, el valor se actualiza con '
                  'el precio real. Solo se consulta el símbolo.',
              helperMaxLines: 3,
              border: OutlineInputBorder(),
            ),
          ),
          TextField(
            controller: _units,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cantidad de acciones o unidades',
              hintText: 'Ej: 2,5',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('En pesos')),
            ButtonSegment(value: true, label: Text('En dólares')),
          ],
          selected: {_inUsd},
          onSelectionChanged: (selection) {
            setState(() => _inUsd = selection.first);
            if (_inUsd && _rate.text.isEmpty) unawaited(_loadRate());
          },
        ),
        if (_inUsd) ...[
          UsdField(
            controller: _investedUsd,
            label: 'Valor invertido en dólares',
            helperText:
                _pesosHint(UsdField.read(_investedUsd)) ??
                'Lo que pagaste, con comisiones. Ej: 253,70',
            onChanged: (_) => setState(() {}),
          ),
          MoneyField(
            controller: _rate,
            label: 'Precio del dólar (en pesos)',
            helperText: _loadingRate
                ? 'Consultando el dólar de hoy…'
                : _rateFromMarket
                ? 'Dólar de hoy (Yahoo). Si lo compraste a otro precio, '
                      'cámbialo.'
                : 'A cuánto compraste los dólares.',
            onChanged: (_) => setState(() {}),
          ),
          if (!_hasSymbol)
            UsdField(
              controller: _currentUsd,
              label: 'Valor actual en dólares (opcional)',
              helperText:
                  _pesosHint(UsdField.read(_currentUsd)) ??
                  'Si lo dejas vacío, se conserva el valor que tenía.',
              onChanged: (_) => setState(() {}),
            ),
        ] else ...[
          MoneyField(
            controller: _invested,
            label: 'Valor invertido',
            helperText: 'Lo que pagaste en pesos, con comisiones.',
          ),
          MoneyField(
            controller: _current,
            label: 'Valor actual',
            helperText:
                'Con símbolo se calcula solo; si no, actualízalo con '
                'tu extracto.',
          ),
        ],
        DateTile(
          label: 'Fecha de inversión',
          value: _date,
          lastDate: DateTime.now(),
          onChanged: (date) => setState(() => _date = date),
        ),
      ],
    );
  }

  bool get _hasSymbol =>
      _marketTypes.contains(_type) && _symbol.text.trim().isNotEmpty;

  /// "≈ $1.040.000 pesos" con el dólar escrito.
  String? _pesosHint(int? usdCents) {
    final rate = _usdRate;
    if (usdCents == null || rate == null || !rate.isValid) return null;
    return '≈ ${Formatters.money(rate.toPesos(usdCents))} pesos';
  }

  Future<void> _loadRate() async {
    setState(() => _loadingRate = true);
    final rate = await ref.read(usdRateProvider.future);
    if (!mounted) return;
    setState(() {
      _loadingRate = false;
      if (rate != null && _rate.text.isEmpty) {
        _rate.text = Formatters.pesos(
          rate.pesosPerDollar.cents ~/ Money.centsPerPeso,
        );
        _rateFromMarket = true;
      }
    });
  }

  Future<void> _save() async {
    final previous = widget.investment;
    final investedUsd = _inUsd ? UsdField.read(_investedUsd) ?? 0 : null;
    final currentUsd = _inUsd && !_hasSymbol
        ? UsdField.read(_currentUsd)
        : null;
    final invested = _inUsd
        ? previous?.investedAmount ?? Money.zero
        : MoneyField.read(_invested) ?? Money.zero;
    final current = _inUsd
        ? previous?.currentValue ??
              (_usdRate?.isValid ?? false
                  ? _usdRate!.toPesos(investedUsd!)
                  : Money.zero)
        : MoneyField.read(_current) ?? invested;
    final market = _marketTypes.contains(_type);
    final result = await ref
        .read(saveInvestmentProvider)
        .call(
          id: previous?.id,
          name: _name.text,
          type: _type,
          invested: invested,
          currentValue: current,
          date: _date,
          notes: previous?.notes,
          symbol: market ? _symbol.text : null,
          unitsMicros: market ? _readUnits(_units.text) : null,
          // Si escribiste otro valor a mano, ya no es el precio de mercado.
          priceUpdatedAt:
              current == previous?.currentValue && currentUsd == null
              ? previous?.priceUpdatedAt
              : null,
          investedUsdCents: investedUsd,
          currentUsdCents: currentUsd,
          usdRate: _inUsd ? _usdRate : null,
        );
    if (!mounted) return;
    if (showResult(context, result, success: 'Inversión guardada')) {
      // Con símbolo, se valora de una vez con el precio real.
      if (_hasSymbol) {
        ref.read(investmentPricesRequestProvider.notifier).refresh();
      }
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
