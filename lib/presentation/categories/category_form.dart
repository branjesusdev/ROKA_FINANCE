import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Crea (o edita, con `editing`) una categoría. Devuelve la guardada.
Future<Category?> showCategoryForm(
  BuildContext context, {
  required CategoryKind kind,
  Category? editing,
}) => showFormSheet<Category>(
  context,
  CategoryForm(kind: kind, editing: editing),
);

class CategoryForm extends ConsumerStatefulWidget {
  const new({required this.kind, this.editing, super.key});

  final CategoryKind kind;
  final Category? editing;

  @override
  ConsumerState<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<CategoryForm> {
  static const _nameMaxLength = 30;

  late final _name = TextEditingController(text: widget.editing?.name);
  late String _iconKey = widget.editing?.iconKey ?? 'other';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.kind == CategoryKind.expense;
    final keys = {...CategoryStyle.choosableKeys, _iconKey};
    final newTitle = isExpense
        ? 'Nueva categoría de gasto'
        : 'Nueva categoría de ingreso';
    return FormSheet(
      title: widget.editing == null ? newTitle : 'Editar categoría',
      onSave: _saving || _name.text.trim().isEmpty ? null : _save,
      children: [
        TextField(
          controller: _name,
          autofocus: widget.editing == null,
          maxLength: _nameMaxLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Nombre',
            hintText: isExpense ? 'Ej: Mascotas' : 'Ej: Ventas',
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        Text('Icono', style: Theme.of(context).textTheme.titleSmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final key in keys)
              _IconChoice(
                iconKey: key,
                selected: key == _iconKey,
                onTap: () => setState(() => _iconKey = key),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final editing = widget.editing;
    final result = editing == null
        ? await ref
              .read(createCategoryProvider)
              .call(name: _name.text, kind: widget.kind, iconKey: _iconKey)
        : await ref
              .read(updateCategoryProvider)
              .call(editing, name: _name.text, iconKey: _iconKey);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!showResult(context, result)) return;
    if (result case Ok(:final value)) Navigator.of(context).pop(value);
  }
}

class _IconChoice extends StatelessWidget {
  const new({
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  static const _size = 44.0;
  static const _selectedAlpha = 0.3;
  static const _idleAlpha = 0.12;

  @override
  Widget build(BuildContext context) {
    final color = CategoryStyle.color(iconKey);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(
              alpha: selected ? _selectedAlpha : _idleAlpha,
            ),
            border: selected ? Border.all(color: color, width: 2) : null,
          ),
          child: Icon(CategoryStyle.icon(iconKey), color: color, size: 22),
        ),
      ),
    );
  }
}
