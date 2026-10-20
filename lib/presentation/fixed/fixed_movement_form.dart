import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/fixed/fixed_movements_screen.dart';
import 'package:finance_app/presentation/shared/category_picker.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Crear o editar un movimiento fijo.
class FixedMovementFormSheet extends ConsumerStatefulWidget {
  const new({this.movement, super.key});

  final FixedMovement? movement;

  @override
  ConsumerState<FixedMovementFormSheet> createState() =>
      _FixedMovementFormSheetState();
}

class _FixedMovementFormSheetState
    extends ConsumerState<FixedMovementFormSheet> {
  late final _name = TextEditingController(text: widget.movement?.name);
  late final _amount = TextEditingController(
    text: MoneyField.initial(widget.movement?.amount),
  );
  late TransactionKind _kind = widget.movement?.kind ?? TransactionKind.expense;
  late String? _categoryId = widget.movement?.categoryId;
  late int _day = widget.movement?.dayOfMonth ?? DateTime.now().day;
  late bool _isActive = widget.movement?.isActive ?? true;
  late bool _isVariable = widget.movement?.isVariable ?? false;
  late bool _autoDebit = widget.movement?.autoDebit ?? false;

  /// Crédito que paga esta cuota (solo en la categoría Deudas).
  late String? _debtId = widget.movement?.debtId;
  bool _alreadyPaid = true;
  bool _saving = false;

  static const _debtsId = DefaultCategories.debtsId;

  bool get _isNew => widget.movement == null;
  bool get _isExpense => _kind == TransactionKind.expense;

  /// Si el día elegido ya pasó en el ciclo actual.
  bool _dayPassed(WidgetRef ref) {
    final now = ref.read(clockProvider).now();
    final today = DateTime(now.year, now.month, now.day);
    final cycle = ref.watch(cycleSummaryProvider).value?.cycle;
    if (cycle == null) return _day < today.day;
    return cycle.datesForDayOfMonth(_day).any((d) => !d.isAfter(today));
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = (ref.watch(categoriesProvider).value ?? const [])
        .where(
          (c) =>
              !c.isArchived &&
              c.kind ==
                  (_kind == TransactionKind.expense
                      ? CategoryKind.expense
                      : CategoryKind.income),
        )
        .toList();
    final canSave =
        !_saving &&
        _categoryId != null &&
        (MoneyField.read(_amount)?.isPositive ?? false) &&
        _name.text.trim().isNotEmpty;
    final dayPassed = _isNew && _dayPassed(ref);

    return FormSheet(
      title: _isNew ? 'Nuevo fijo' : 'Editar fijo',
      onSave: canSave ? _save : null,
      extraActions: [
        if (!_isNew)
          TextButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (await deleteFixedMovement(context, ref, widget.movement!)) {
                navigator.pop();
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar fijo'),
          ),
      ],
      children: [
        if (_isNew)
          SegmentedButton<TransactionKind>(
            segments: const [
              ButtonSegment(
                value: TransactionKind.expense,
                label: Text('Gasto fijo'),
              ),
              ButtonSegment(
                value: TransactionKind.income,
                label: Text('Ingreso fijo'),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              _categoryId = null;
            }),
          ),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Nombre',
            hintText: _kind == TransactionKind.expense
                ? 'Ej: Arriendo, Colegio, Entrenos'
                : 'Ej: Sueldo',
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        MoneyField(
          controller: _amount,
          label: _isVariable ? 'Valor estimado' : 'Valor mensual',
          onChanged: (_) => setState(() {}),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _isVariable,
          onChanged: (v) => setState(() => _isVariable = v),
          title: const Text('El valor cambia cada mes'),
          subtitle: Text(
            _isExpense
                ? 'Agua, luz, gas, internet, celular. Ese día te pregunta '
                      'el valor de la factura; mientras tanto se usa el '
                      'estimado.'
                : 'Comisiones o pagos que varían. Ese día te pregunta '
                      'cuánto llegó.',
          ),
        ),
        if (_isExpense && !_isVariable)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _autoDebit,
            onChanged: (v) => setState(() => _autoDebit = v),
            title: const Text('Se descuenta solo (débito automático)'),
            subtitle: Text(
              _autoDebit
                  ? 'Ese día queda como pagado sin preguntarte.'
                  : 'Ese día te pregunta "¿Ya lo pagaste?" y te recuerda en '
                        'la mañana, la tarde y la noche hasta que lo '
                        'confirmes.',
            ),
          ),
        DropdownButtonFormField<int>(
          initialValue: _day,
          decoration: InputDecoration(
            labelText: _kind == TransactionKind.expense
                ? 'Día de pago'
                : 'Día en que llega',
            border: const OutlineInputBorder(),
          ),
          items: [
            for (var d = FixedMovement.minDay; d <= FixedMovement.maxDay; d++)
              DropdownMenuItem(value: d, child: Text('Día $d')),
          ],
          onChanged: (d) => setState(() => _day = d ?? _day),
        ),
        CategoryPicker(
          categories: categories,
          selectedId: _categoryId,
          onSelected: (id) => setState(() => _categoryId = id),
        ),
        if (_isExpense && (_debtId != null || _categoryId == _debtsId))
          _DebtPicker(
            debtId: _debtId,
            onChanged: (id) => setState(() => _debtId = id),
          ),
        if (dayPassed)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _alreadyPaid,
            onChanged: (v) => setState(() => _alreadyPaid = v),
            title: Text(
              _isExpense ? 'Ya lo pagué este mes' : 'Ya lo recibí este mes',
            ),
            subtitle: Text(
              _alreadyPaid
                  ? 'El día $_day ya pasó: no se descuenta otra vez de lo que '
                        'te queda (tu dinero real ya lo incluye).'
                  : _isExpense && (_isVariable || !_autoDebit)
                  ? 'Te preguntará si ya lo pagaste.'
                  : 'Se registrará con fecha del día $_day.',
            ),
          )
        else if (!_isNew)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Activo'),
            subtitle: const Text('Si lo pausas no se registra.'),
          ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref
        .read(saveFixedMovementProvider)
        .call(
          id: widget.movement?.id,
          name: _name.text,
          kind: _kind,
          amount: MoneyField.read(_amount)!,
          categoryId: _categoryId!,
          dayOfMonth: _day,
          isActive: _isActive,
          isVariable: _isVariable,
          autoDebit: _autoDebit && !_isVariable,
          lastPostedOn: widget.movement?.lastPostedOn,
          registerInCurrentCycle: !_alreadyPaid,
          debtId: _debtId,
        );
    if (!mounted) return;
    if (showResult(context, result, success: 'Fijo guardado')) {
      // Si su día ya llegó, se registra de inmediato.
      final postDue = ref.read(postDueFixedMovementsProvider);
      Navigator.of(context).pop();
      await postDue();
    } else {
      setState(() => _saving = false);
    }
  }
}

/// "¿Qué crédito paga?": al registrarse la cuota baja el saldo del crédito
/// y sus avisos dicen cuánto te falta.
class _DebtPicker extends ConsumerWidget {
  const new({required this.debtId, required this.onChanged});

  final String? debtId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = (ref.watch(debtsProvider).value ?? const [])
        .where((d) => d.currentBalance.isPositive || d.id == debtId)
        .toList();
    if (debts.isEmpty) {
      return const Text(
        'Si es la cuota de un crédito, créalo en Patrimonio › Deudas y '
        'enlázalo aquí para que baje su saldo solo.',
      );
    }
    return DropdownButtonFormField<String?>(
      initialValue: debts.any((d) => d.id == debtId) ? debtId : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: '¿Qué crédito paga? (opcional)',
        helperText:
            'Al registrarse, baja el saldo y suma la cuota pagada. Los '
            'avisos te dicen cuántas cuotas te faltan.',
        helperMaxLines: 3,
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(child: Text('Ninguno')),
        for (final d in debts)
          DropdownMenuItem(value: d.id, child: Text(d.name)),
      ],
      onChanged: onChanged,
    );
  }
}
