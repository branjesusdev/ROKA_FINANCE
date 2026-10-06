import 'dart:async';

import 'package:finance_app/application/transactions/frequent_categories.dart';
import 'package:finance_app/application/transactions/register_transaction.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/quick_entry/voice_entry_sheet.dart';
import 'package:finance_app/presentation/shared/category_picker.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre el registro rápido. Flujo: monto → categoría → Guardar.
/// Con [draft] (p. ej. dictado por voz) el formulario llega prellenado para
/// revisar y confirmar.
Future<void> showQuickEntrySheet(BuildContext context, {VoiceDraft? draft}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => QuickEntrySheet(draft: draft),
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
  const new({this.draft, super.key});

  final VoiceDraft? draft;

  @override
  ConsumerState<QuickEntrySheet> createState() => _QuickEntrySheetState();
}

class _QuickEntrySheetState extends ConsumerState<QuickEntrySheet> {
  late final _amount = TextEditingController(
    text: widget.draft?.pesos == null
        ? null
        : Formatters.pesos(widget.draft!.pesos!),
  );
  late final _description = TextEditingController(
    text: widget.draft?.description,
  );
  late TransactionKind _kind = widget.draft?.kind ?? TransactionKind.expense;
  late String? _categoryId = widget.draft?.categoryId;
  late DateTime? _date = widget.draft?.date;
  ExpenseNature? _nature;
  bool _showAllCategories = false;
  bool _saving = false;

  int? get _pesos => PesosInputFormatter.parse(_amount.text);
  bool get _isExpense => _kind == TransactionKind.expense;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
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
              autofocus: widget.draft == null,
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
              trailing: all.length > visible.length || _showAllCategories
                  ? ActionChip(
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
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              initiallyExpanded:
                  widget.draft?.description != null ||
                  widget.draft?.date != null,
              tilePadding: EdgeInsets.zero,
              title: const Text('Más detalles (opcional)'),
              children: [
                TextField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej: Mercado',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _date == null ? 'Hoy' : Formatters.longDate(_date!),
                  ),
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
              label: Text(_isExpense ? 'Guardar gasto' : 'Guardar ingreso'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(String categoryId) async {
    setState(() => _saving = true);
    final result = await ref
        .read(registerTransactionProvider)
        .call(
          RegisterTransactionInput(
            kind: _kind,
            amount: Money.pesos(_pesos!),
            categoryId: categoryId,
            date: _date,
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
              _isExpense ? 'Gasto registrado' : 'Ingreso registrado',
            ),
          ),
        );
      case Err():
        setState(() => _saving = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar. Intenta de nuevo.'),
          ),
        );
    }
  }
}
