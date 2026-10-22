import 'dart:async';

import 'package:finance_app/application/transactions/description_suggestions.dart';
import 'package:finance_app/application/transactions/frequent_categories.dart';
import 'package:finance_app/application/transactions/register_transaction.dart';
import 'package:finance_app/application/transactions/update_transaction.dart';
import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/cycle_recount.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/fixed/fixed_payment_matcher.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/fuel_economy.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/categories/category_form.dart';
import 'package:finance_app/presentation/quick_entry/voice_entry_sheet.dart';
import 'package:finance_app/presentation/shared/category_picker.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/recount_badge.dart';
import 'package:finance_app/presentation/windfall/windfall_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre el registro rápido. Flujo: monto → categoría → Guardar.
/// Con [draft] (p. ej. dictado por voz) el formulario llega prellenado para
/// revisar y confirmar. Con [editing] corrige o elimina ese movimiento.
Future<void> showQuickEntrySheet(
  BuildContext context, {
  VoiceDraft? draft,
  Transaction? editing,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => QuickEntrySheet(draft: draft, editing: editing),
);

/// Datos sugeridos para prellenar el registro.
final class VoiceDraft {
  const new({
    required this.kind,
    this.pesos,
    this.categoryId,
    this.description,
    this.date,
    this.heard,
  });

  final TransactionKind kind;
  final int? pesos;
  final String? categoryId;
  final String? description;
  final DateTime? date;

  /// Frase reconocida, para mostrarla al usuario.
  final String? heard;
}

class QuickEntrySheet extends ConsumerStatefulWidget {
  const new({this.draft, this.editing, super.key});

  final VoiceDraft? draft;
  final Transaction? editing;

  @override
  ConsumerState<QuickEntrySheet> createState() => _QuickEntrySheetState();
}

class _QuickEntrySheetState extends ConsumerState<QuickEntrySheet> {
  static const _descriptionMaxLength = 60;

  late final _amount = TextEditingController(
    text: switch ((widget.editing, widget.draft?.pesos)) {
      (final editing?, _) => Formatters.pesos(
        editing.amount.cents ~/ Money.centsPerPeso,
      ),
      (_, final pesos?) => Formatters.pesos(pesos),
      _ => null,
    },
  );
  late final _description = TextEditingController(
    text: widget.editing?.description ?? widget.draft?.description,
  );
  late TransactionKind _kind =
      widget.editing?.kind ?? widget.draft?.kind ?? TransactionKind.expense;
  late String? _categoryId =
      widget.editing?.categoryId ?? widget.draft?.categoryId;
  late DateTime? _date = widget.editing?.date ?? widget.draft?.date;
  late ExpenseNature? _nature = widget.editing?.nature;
  late final _odometer = TextEditingController(
    text: switch (widget.editing?.odometerKm) {
      final km? => Formatters.pesos(km),
      null => null,
    },
  );
  final _descriptionFocus = FocusNode();

  /// Reconteo al registrar el sueldo: lo que de verdad tenías antes.
  final _recount = TextEditingController();
  bool _showAllCategories = false;
  bool _saving = false;

  /// Ya elegiste una sugerencia: no se vuelve a mostrar hasta que escribas.
  late bool _suggestionPicked = _description.text.isNotEmpty;

  int? get _pesos => PesosInputFormatter.parse(_amount.text);
  bool get _isExpense => _kind == TransactionKind.expense;
  bool get _isEditing => widget.editing != null;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _odometer.dispose();
    _recount.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _createCategory(CategoryKind kind) async {
    final created = await showCategoryForm(context, kind: kind);
    if (created != null && mounted) {
      setState(() => _categoryId = created.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final recent = ref.watch(last30DaysTransactionsProvider).value ?? const [];
    final categoryKind = _isExpense
        ? CategoryKind.expense
        : CategoryKind.income;
    final frequent = const FrequentCategories().select(
      categories: categories,
      recent: recent,
      kind: categoryKind,
    );
    final all = categories
        .where((c) => c.kind == categoryKind && !c.isArchived)
        .toList();
    // Sin elección del usuario se preselecciona la más frecuente.
    final selectedId = _categoryId ?? frequent.firstOrNull?.id;
    final selected = all.where((c) => c.id == selectedId).firstOrNull;
    final visible = _showAllCategories
        ? all
        : [?selected, ...frequent.where((c) => c.id != selectedId)];
    final heard = widget.draft?.heard;
    final canSave = (_pesos ?? 0) > 0 && selectedId != null && !_saving;
    final history = ref.watch(lastYearTransactionsProvider).value ?? const [];
    final suggestions = _suggestionPicked
        ? const <DescriptionSuggestion>[]
        : const DescriptionSuggestions().suggest(
            query: _description.text,
            kind: _kind,
            history: history,
            categories: categories,
            fixed: ref.watch(fixedMovementsProvider).value ?? const [],
          );
    final tracksKm = _isExpense && FuelEconomyCalculator.appliesTo(selected);
    final asksRecount = _asksRecount(selectedId);
    final fuel = tracksKm
        ? const FuelEconomyCalculator().compute(
            history.where(
              (t) => t.categoryId == selectedId && t.id != widget.editing?.id,
            ),
          )
        : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (heard != null) ...[
              Text(
                'Escuché: "$heard"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text('Revisa y confirma.', style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
            ] else if (_isEditing) ...[
              Text('Editar movimiento', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
            ] else ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _switchToVoice,
                  icon: const Icon(Icons.mic),
                  label: const Text('Dictar por voz'),
                ),
              ),
            ],
            SegmentedButton<TransactionKind>(
              segments: const [
                ButtonSegment(
                  value: TransactionKind.expense,
                  label: Text('Gasto'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: TransactionKind.income,
                  label: Text('Ingreso'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) => setState(() {
                _kind = selection.first;
                _categoryId = null;
                _showAllCategories = false;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              autofocus: widget.draft == null && !_isEditing,
              keyboardType: TextInputType.number,
              inputFormatters: [PesosInputFormatter()],
              style: theme.textTheme.headlineMedium,
              decoration: const InputDecoration(
                prefixText: r'$ ',
                hintText: '0',
                labelText: 'Valor',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _description,
              focusNode: _descriptionFocus,
              textCapitalization: TextCapitalization.sentences,
              maxLength: _descriptionMaxLength,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Ej: Mercado del mes',
                helperText:
                    'Escribe y elige algo que ya anotaste: se pone '
                    'su categoría.',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _suggestionPicked = false),
            ),
            if (suggestions.isNotEmpty)
              _Suggestions(
                suggestions: suggestions,
                categories: categories,
                onPick: _pickSuggestion,
              ),
            const SizedBox(height: 8),
            Text('Categoría', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            CategoryPicker(
              categories: visible,
              selectedId: selectedId,
              onSelected: (id) => setState(() => _categoryId = id),
              trailing: Wrap(
                spacing: 8,
                children: [
                  if (all.length > visible.length || _showAllCategories)
                    ActionChip(
                      avatar: Icon(
                        _showAllCategories
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                      ),
                      label: Text(_showAllCategories ? 'Menos' : 'Todas'),
                      onPressed: () => setState(
                        () => _showAllCategories = !_showAllCategories,
                      ),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Nueva'),
                    onPressed: () => _createCategory(categoryKind),
                  ),
                ],
              ),
            ),

            if (tracksKm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _odometer,
                keyboardType: TextInputType.number,
                inputFormatters: [PesosInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Kilometraje del vehículo (opcional)',
                  suffixText: 'km',
                  helperText: fuel == null
                      ? 'Si es gasolina, anota el kilometraje al tanquear: '
                            'así sabrás cuánto te cuesta cada km.'
                      : 'La última vez: '
                            '${Formatters.pesos(fuel.lastOdometerKm)} km.',
                  helperMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            if (asksRecount) ...[
              const SizedBox(height: 12),
              _RecountField(controller: _recount),
            ],
            ExpansionTile(
              initiallyExpanded:
                  widget.draft?.date != null || widget.editing?.nature != null,
              tilePadding: EdgeInsets.zero,
              title: const Text('Fecha y tipo de gasto (opcional)'),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _date == null ? 'Hoy' : Formatters.longDate(_date!),
                  ),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
                ),
                if (_isExpense)
                  SegmentedButton<ExpenseNature>(
                    emptySelectionAllowed: true,
                    segments: const [
                      ButtonSegment(
                        value: ExpenseNature.essential,
                        label: Text('Esencial'),
                      ),
                      ButtonSegment(
                        value: ExpenseNature.discretionary,
                        label: Text('No esencial'),
                      ),
                    ],
                    selected: {?_nature},
                    onSelectionChanged: (selection) =>
                        setState(() => _nature = selection.firstOrNull),
                  ),
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: canSave ? () => _save(selectedId) : null,
              icon: const Icon(Icons.check),
              label: Text(
                _isEditing
                    ? 'Guardar cambios'
                    : _isExpense
                    ? 'Guardar gasto'
                    : 'Guardar ingreso',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(_isExpense ? 'Eliminar gasto' : 'Eliminar ingreso'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _pickSuggestion(DescriptionSuggestion suggestion) {
    setState(() {
      _description.text = suggestion.text;
      _description.selection = TextSelection.collapsed(
        offset: suggestion.text.length,
      );
      _categoryId = suggestion.categoryId;
      _suggestionPicked = true;
    });
    _descriptionFocus.unfocus();
  }

  void _switchToVoice() {
    final navigator = Navigator.of(context);
    final parent = navigator.context;
    navigator.pop();
    unawaited(showVoiceEntrySheet(parent));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: initial.isAfter(now) ? initial : now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(String categoryId) async {
    final editing = widget.editing;
    final amount = Money.pesos(_pesos!);
    if (editing == null && _isExpense) {
      final schedule = ref.read(cycleSummaryProvider).value?.upcomingFixed;
      final match = schedule == null
          ? null
          : const FixedPaymentMatcher().match(
              schedule: schedule,
              categoryId: categoryId,
              amount: amount,
            );
      if (match != null) {
        final answer = await _askIsFixed(match);
        if (answer == null || !mounted) return;
        if (answer) {
          await _payFixed(match, amount);
          return;
        }
      }
    }
    setState(() => _saving = true);
    final recount = await _applyRecount(categoryId);
    if (!mounted) return;
    final result = editing == null
        ? await ref
              .read(registerTransactionProvider)
              .call(
                RegisterTransactionInput(
                  kind: _kind,
                  amount: amount,
                  categoryId: categoryId,
                  date: _date,
                  description: _description.text,
                  nature: _nature,
                  odometerKm: _odometerKm(categoryId),
                ),
              )
        : await ref
              .read(updateTransactionProvider)
              .call(
                UpdateTransactionInput(
                  id: editing.id,
                  kind: _kind,
                  amount: amount,
                  categoryId: categoryId,
                  date: _date ?? editing.date,
                  description: _description.text,
                  nature: _nature,
                  odometerKm: _odometerKm(categoryId),
                ),
              );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Ok(:final value):
        final fuelNote = _fuelNote(value);
        final navigator = Navigator.of(context);
        final parent = navigator.context;
        final category = (ref.read(categoriesProvider).value ?? const [])
            .where((c) => c.id == categoryId)
            .firstOrNull;
        navigator.pop();
        if (editing == null &&
            !_isExpense &&
            (category?.isExtraordinary ?? false) &&
            parent.mounted) {
          unawaited(
            showWindfallSheet(
              parent,
              amount: amount,
              sourceName: category!.name,
            ),
          );
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              [
                if (_isEditing)
                  'Cambios guardados'
                else if (_isExpense)
                  'Gasto registrado'
                else
                  'Ingreso registrado',
                ?fuelNote,
                ?recount,
              ].join('. '),
            ),
          ),
        );
      case Err(:final failure):
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(content: Text(failureMessage(failure))),
        );
    }
  }

  /// Al registrar un sueldo nuevo se ofrece recontar el ciclo que cierra.
  bool _asksRecount(String? categoryId) =>
      !_isEditing && !_isExpense && categoryId == DefaultCategories.salaryId;

  /// Cuadra el ciclo que se cierra (el día antes del sueldo) con lo que de
  /// verdad quedaba. Devuelve el texto para el aviso, o `null`.
  Future<String?> _applyRecount(String categoryId) async {
    final actual = PesosInputFormatter.parse(_recount.text);
    if (!_asksRecount(categoryId) || actual == null) return null;
    final now = ref.read(clockProvider).now();
    final day = _date ?? now;
    final result = await ref
        .read(reconcileBalanceProvider)
        .call(
          actual: Money.pesos(actual),
          closingOn: DateTime(day.year, day.month, day.day - 1),
        );
    return switch (result) {
      Ok(:final value) when value.difference.isZero =>
        'Reconteo: cuadra exacto',
      Ok(:final value) =>
        'Reconteo: diferencia de ${Formatters.money(value.difference)}',
      Err() => null,
    };
  }

  /// Kilometraje escrito, solo si la categoría lo admite.
  int? _odometerKm(String categoryId) {
    final category = (ref.read(categoriesProvider).value ?? const [])
        .where((c) => c.id == categoryId)
        .firstOrNull;
    if (!_isExpense || !FuelEconomyCalculator.appliesTo(category)) return null;
    return PesosInputFormatter.parse(_odometer.text);
  }

  /// "Te costó $350 por km desde la última tanqueada".
  String? _fuelNote(Transaction saved) {
    if (saved.odometerKm == null) return null;
    final history = ref.read(lastYearTransactionsProvider).value ?? const [];
    final fuel = const FuelEconomyCalculator().compute([
      ...history.where(
        (t) => t.categoryId == saved.categoryId && t.id != saved.id,
      ),
      saved,
    ]);
    final perKm = fuel?.lastCostPerKm;
    if (fuel == null || perKm == null) return null;
    return 'Te costó ${Formatters.money(perKm)} por km en los últimos '
        '${Formatters.pesos(fuel.lastSegmentKm!)} km';
  }

  /// `true`: es ese pago fijo; `false`: es otro gasto; `null`: canceló.
  Future<bool?> _askIsFixed(ScheduledFixed match) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.event_repeat),
      title: Text('¿Es el pago de ${match.movement.name}?'),
      content: Text(
        'Tienes ${match.movement.name} por '
        '${Formatters.money(match.movement.amount)} con fecha '
        '${Formatters.shortDate(match.date)} y aún no está registrado. Si es '
        'ese pago, lo marco como pagado para no contarlo dos veces.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No, es otro gasto'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sí, es ese pago'),
        ),
      ],
    ),
  );

  Future<void> _payFixed(ScheduledFixed match, Money amount) async {
    setState(() => _saving = true);
    final result = await ref
        .read(confirmVariableFixedProvider)
        .call(
          movement: match.movement,
          scheduledDate: match.date,
          amount: amount,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (showResult(
      context,
      result,
      success: '${match.movement.name} quedó pagado',
    )) {
      Navigator.of(context).pop();
    }
  }

  /// Elimina y ofrece deshacer, igual que al deslizar en Movimientos.
  Future<void> _delete() async {
    final editing = widget.editing!;
    setState(() => _saving = true);
    final useCase = ref.read(deleteTransactionProvider);
    final result = await useCase(editing.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Movimiento eliminado'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () => useCase.undo(editing),
            ),
          ),
        );
      case Err(:final failure):
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(content: Text(failureMessage(failure))),
        );
    }
  }
}

/// Lista corta de cosas que ya anotaste; tocar una llena la descripción y
/// elige su categoría.
class _Suggestions extends StatelessWidget {
  const new({
    required this.suggestions,
    required this.categories,
    required this.onPick,
  });

  final List<DescriptionSuggestion> suggestions;
  final List<Category> categories;
  final ValueChanged<DescriptionSuggestion> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byId = {for (final c in categories) c.id: c};
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          for (final s in suggestions)
            ListTile(
              dense: true,
              leading: CategoryAvatar(category: byId[s.categoryId], size: 28),
              title: Text(s.text, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                [
                  byId[s.categoryId]?.name ?? '',
                  if (s.isFixed)
                    'fijo'
                  else if (s.count > 1)
                    '${s.count} veces',
                  if (s.lastAmount case final amount?)
                    '${s.isFixed ? '' : 'última '}${Formatters.money(amount)}',
                ].where((p) => p.isNotEmpty).join(' · '),
              ),
              onTap: () => onPick(s),
            ),
        ],
      ),
    );
  }
}

/// "¿Cuánto tenías antes de este sueldo?": compara con lo registrado del
/// ciclo que se cierra y muestra la diferencia con su color (normal, aviso o
/// desbalance grande).
class _RecountField extends ConsumerStatefulWidget {
  const new({required this.controller});

  final TextEditingController controller;

  @override
  ConsumerState<_RecountField> createState() => _RecountFieldState();
}

class _RecountFieldState extends ConsumerState<_RecountField> {
  @override
  Widget build(BuildContext context) {
    final registered = ref.watch(cycleMovementsProvider(0)).value?.left;
    final actual = PesosInputFormatter.parse(widget.controller.text);
    final recount = registered == null || actual == null
        ? null
        : CycleRecount.measure(
            registered: registered,
            actual: Money.pesos(actual),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          inputFormatters: [PesosInputFormatter()],
          decoration: InputDecoration(
            labelText: 'Reconteo: ¿cuánto tenías antes de este sueldo?',
            prefixText: r'$ ',
            helperText: registered == null
                ? 'Opcional. Lo que de verdad quedaba en tu cuenta y '
                      'efectivo.'
                : 'Opcional. Según lo registrado te quedaban '
                      '${Formatters.money(registered)}.',
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (recount != null) ...[
          const SizedBox(height: 8),
          RecountBadge(recount: recount),
        ],
      ],
    );
  }
}
