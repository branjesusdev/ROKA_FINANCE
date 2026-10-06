import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:flutter/material.dart';

/// Chips de categoría con su icono y color.
class CategoryPicker extends StatelessWidget {
  const new({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.trailing,
    super.key,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  /// Chip extra al final (p. ej. "Todas").
  final Widget? trailing;

  static const _selectedAlpha = 0.22;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in categories)
          ChoiceChip(
            avatar: Icon(
              CategoryStyle.icon(category.iconKey),
              size: 18,
              color: CategoryStyle.color(category.iconKey),
            ),
            label: Text(category.name),
            selected: category.id == selectedId,
            selectedColor: CategoryStyle.color(category.iconKey)
                .withValues(alpha: _selectedAlpha),
            showCheckmark: false,
            onSelected: (_) => onSelected(category.id),
          ),
        ?trailing,
      ],
    );
  }
}
