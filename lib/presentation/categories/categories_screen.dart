import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/presentation/categories/category_form.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ver, crear, renombrar y ocultar categorías. Ocultar no borra: los
/// movimientos antiguos conservan su categoría.
class CategoriesScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryKind _kind = CategoryKind.expense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryForm(context, kind: _kind),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: AsyncView(
        value: ref.watch(categoriesProvider),
        builder: (all) {
          final mine = all.where((c) => c.kind == _kind).toList();
          final active = mine.where((c) => !c.isArchived).toList();
          final hidden = mine.where((c) => c.isArchived).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              SegmentedButton<CategoryKind>(
                segments: const [
                  ButtonSegment(
                    value: CategoryKind.expense,
                    label: Text('Gastos'),
                  ),
                  ButtonSegment(
                    value: CategoryKind.income,
                    label: Text('Ingresos'),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 8),
              for (final c in active) _CategoryRow(category: c),
              if (hidden.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Ocultas', style: Theme.of(context).textTheme.titleSmall),
                for (final c in hidden) _CategoryRow(category: c),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const new({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = category.isArchived;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CategoryAvatar(category: category, size: 40),
      title: Text(category.name),
      subtitle: hidden ? const Text('No aparece al registrar') : null,
      onTap: () =>
          showCategoryForm(context, kind: category.kind, editing: category),
      trailing: IconButton(
        tooltip: hidden ? 'Mostrar' : 'Ocultar',
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () async {
          final result = await ref
              .read(updateCategoryProvider)
              .call(category, isArchived: !hidden);
          if (context.mounted) showResult(context, result);
        },
      ),
    );
  }
}
