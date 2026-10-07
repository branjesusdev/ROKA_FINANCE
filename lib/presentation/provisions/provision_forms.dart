import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/provisions/provision_planner.dart';
import 'package:finance_app/presentation/provisions/provision_templates.dart';
import 'package:finance_app/presentation/shared/category_picker.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Crear (desde cero o desde un atajo) o editar un pago que no es mensual.
class ProvisionFormSheet extends ConsumerStatefulWidget {
  const new({this.provision, this.template, super.key});

  final Provision? provision;
  final ProvisionTemplate? template;

  @override
  ConsumerState<ProvisionFormSheet> createState() => _ProvisionFormSheetState();
}

class _ProvisionFormSheetState extends ConsumerState<ProvisionFormSheet> {
  static const _monthOptions = [2, 3, 4, 6, 12, 24];

  late final _name = TextEditingController(
    text: widget.provision?.name ?? widget.template?.name,
  );
  late final _amount = TextEditingController(
    text: MoneyField.initial(
      widget.provision?.amount ?? widget.template?.amount,
    ),
  );
  late int _everyMonths =
      widget.provision?.everyMonths ?? widget.template?.everyMonths ?? 12;
  late DateTime? _nextDue =
      widget.provision?.nextDue ??
      widget.template?.suggestedDue(DateTime.now());
  late String? _categoryId =
      widget.provision?.categoryId ?? widget.template?.categoryId;
  late bool _isActive = widget.provision?.isActive ?? true;
  bool _saving = false;

  bool get _isNew => widget.provision == null;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = (ref.watch(categoriesProvider).value ?? const [])
        .where((c) => !c.isArchived && c.kind == CategoryKind.expense)
        .toList();
    final canSave =
        !_saving &&
        _categoryId != null &&
        _nextDue != null &&
        (MoneyField.read(_amount)?.isPositive ?? false) &&
        _name.text.trim().isNotEmpty;
    final months = {..._monthOptions, _everyMonths}.toList()..sort();

    return FormSheet(
      title: _isNew ? 'Nuevo pago del año' : 'Editar pago',
      onSave: canSave ? _save : null,
      extraActions: [
        if (!_isNew)
          TextButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar'),
          ),
      ],
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: SOAT, Matrícula, Gimnasio',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        MoneyField(
          controller: _amount,
          label: 'Cuánto cuesta cada vez',
          onChanged: (_) => setState(() {}),
        ),
        DropdownButtonFormField<int>(
          initialValue: _everyMonths,
          decoration: const InputDecoration(
            labelText: 'Se repite',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final m in months)
              DropdownMenuItem(value: m, child: Text(_everyLabel(m))),
          ],
          onChanged: (m) => setState(() => _everyMonths = m ?? _everyMonths),
        ),
        DateTile(
          label: 'Próximo pago',
          value: _nextDue,
          firstDate: DateTime(DateTime.now().year - 1),
          onChanged: (d) => setState(() => _nextDue = d),
        ),
        CategoryPicker(
          categories: categories,
          selectedId: _categoryId,
          onSelected: (id) => setState(() => _categoryId = id),
        ),
        if (!_isNew)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Activo'),
            subtitle: const Text('Si lo pausas, no te pide apartar.'),
          ),
      ],
    );
  }

  static String _everyLabel(int months) => switch (months) {
    3 => 'Cada 3 meses (trimestral)',
    6 => 'Cada 6 meses (semestral)',
    12 => 'Cada año',
    24 => 'Cada 2 años',
    _ => 'Cada $months meses',
  };

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref
        .read(saveProvisionProvider)
        .call(
          id: widget.provision?.id,
          name: _name.text,
          amount: MoneyField.read(_amount)!,
          everyMonths: _everyMonths,
          nextDue: _nextDue!,
          categoryId: _categoryId!,
          isActive: _isActive,
        );
    if (!mounted) return;
    if (showResult(context, result, success: 'Pago guardado')) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final delete = ref.read(deleteProvisionProvider);
    if (!await confirmDelete(context, 'este pago')) return;
    final result = await delete(widget.provision!.id);
    if (!mounted) return;
    if (showResult(context, result, success: 'Pago eliminado')) {
      navigator.pop();
    }
  }
}

/// Apartar plata para un pago (o devolverla a la billetera).
class SetAsideSheet extends ConsumerStatefulWidget {
  const new({required this.status, super.key});

  final ProvisionStatus status;

  @override
  ConsumerState<SetAsideSheet> createState() => _SetAsideSheetState();
}

class _SetAsideSheetState extends ConsumerState<SetAsideSheet> {
  late final _amount = TextEditingController(
    text: MoneyField.initial(
      widget.status.pendingThisCycle.isPositive
          ? widget.status.pendingThisCycle
          : null,
    ),
  );
  bool _giveBack = false;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final amount = MoneyField.read(_amount);
    return FormSheet(
      title: status.provision.name,
      saveLabel: _giveBack ? 'Devolver a la billetera' : 'Apartar',
      onSave: !_saving && (amount?.isPositive ?? false) ? _save : null,
      children: [
        Text(
          'Llevas ${Formatters.money(status.saved)} de '
          '${Formatters.money(status.amount)}. Este ciclo toca apartar '
          '${Formatters.money(status.perCycle)}.',
        ),
        if (status.saved.isPositive)
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Apartar')),
              ButtonSegment(value: true, label: Text('Devolver')),
            ],
            selected: {_giveBack},
            onSelectionChanged: (s) => setState(() => _giveBack = s.first),
          ),
        MoneyField(
          controller: _amount,
          label: _giveBack ? 'Cuánto devuelves' : 'Cuánto apartas',
          helperText: _giveBack
              ? 'Vuelve a lo disponible de este ciclo.'
              : 'Sale de lo disponible del ciclo (no cuenta como gasto). '
                    'Guárdalo aparte: bolsillo, alcancía o cuenta de ahorro.',
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final amount = MoneyField.read(_amount)!;
    final result = await ref
        .read(setAsideForProvisionProvider)
        .call(
          provision: widget.status.provision,
          amount: _giveBack ? -amount : amount,
        );
    if (!mounted) return;
    if (showResult(
      context,
      result,
      success: _giveBack ? 'Devuelto' : 'Apartado. ¡Bien!',
    )) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }
}

/// "Ya lo pagué": usa lo apartado y programa el siguiente pago.
class PayProvisionSheet extends ConsumerStatefulWidget {
  const new({required this.status, super.key});

  final ProvisionStatus status;

  @override
  ConsumerState<PayProvisionSheet> createState() => _PayProvisionSheetState();
}

class _PayProvisionSheetState extends ConsumerState<PayProvisionSheet> {
  late final _amount = TextEditingController(
    text: MoneyField.initial(widget.status.amount),
  );
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    return FormSheet(
      title: 'Pagaste ${status.provision.name}',
      saveLabel: 'Ya lo pagué',
      onSave: !_saving && (MoneyField.read(_amount)?.isPositive ?? false)
          ? _save
          : null,
      children: [
        MoneyField(
          controller: _amount,
          label: 'Cuánto pagaste',
          onChanged: (_) => setState(() {}),
        ),
        Text(
          'Tenías apartado ${Formatters.money(status.saved)}. Se usa eso '
          'primero; si no alcanza, la diferencia sale de este ciclo. El '
          'próximo pago queda para el '
          '${Formatters.longDate(status.provision.followingDue)}.',
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref
        .read(payProvisionProvider)
        .call(
          provision: widget.status.provision,
          paid: MoneyField.read(_amount),
        );
    if (!mounted) return;
    if (showResult(context, result, success: 'Pago registrado')) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }
}
