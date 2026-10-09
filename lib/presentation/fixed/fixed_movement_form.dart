import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/categories/category.dart';
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
  bool _alreadyPaid = true;
  bool _saving = false;

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
          lastPostedOn: widget.movement?.lastPostedOn,
          registerInCurrentCycle: !_alreadyPaid,
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
