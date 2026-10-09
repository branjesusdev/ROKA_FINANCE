import 'dart:async';

import 'package:finance_app/application/transactions/frequent_categories.dart';
import 'package:finance_app/application/transactions/register_transaction.dart';
import 'package:finance_app/application/transactions/update_transaction.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/categories/category_form.dart';
import 'package:finance_app/presentation/quick_entry/voice_entry_sheet.dart';
import 'package:finance_app/presentation/shared/category_picker.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
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
  bool _showAllCategories = false;
  bool _saving = false;

  int? get _pesos => PesosInputFormatter.parse(_amount.text);
  bool get _isExpense => _kind == TransactionKind.expense;
  bool get _isEditing => widget.editing != null;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
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
            const SizedBox(height: 16),
            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLength: _descriptionMaxLength,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Ej: Mercado del mes',
                border: OutlineInputBorder(),
              ),
            ),
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
    setState(() => _saving = true);
    final editing = widget.editing;
    final amount = Money.pesos(_pesos!);
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
                ),
              );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Cambios guardados'
                  : _isExpense
                  ? 'Gasto registrado'
                  : 'Ingreso registrado',
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
