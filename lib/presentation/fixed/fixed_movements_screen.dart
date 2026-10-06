import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/fixed/fixed_movement_form.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/empty_state.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gastos e ingresos que se repiten cada mes. Se registran solos el día
/// indicado dentro de cada ciclo.
class FixedMovementsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Fijos del mes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showFormSheet<void>(context, const FixedMovementFormSheet()),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo fijo'),
      ),
      body: AsyncView(
        value: ref.watch(fixedMovementsProvider),
        builder: (movements) {
          if (movements.isEmpty) {
            return const EmptyState(
              icon: Icons.event_repeat,
              message:
                  'Agrega arriendo, colegio, cuota alimentaria, entrenos, '
                  'crédito o tu sueldo. Se registran solos cada mes.',
            );
          }
          final expenses = movements.where((m) => m.isExpense).toList();
          final incomes = movements.where((m) => !m.isExpense).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (incomes.isNotEmpty) ...[
                _FixedGroup(
                  title: 'Ingresos fijos',
                  movements: incomes,
                  categories: categories,
                ),
                const SizedBox(height: 12),
              ],
              if (expenses.isNotEmpty)
                _FixedGroup(
                  title: 'Gastos fijos',
                  movements: expenses,
                  categories: categories,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FixedGroup extends StatelessWidget {
  const new({
    required this.title,
    required this.movements,
    required this.categories,
  });

  final String title;
  final List<FixedMovement> movements;
  final Map<String, Category> categories;

  @override
  Widget build(BuildContext context) {
    final active = movements.where((m) => m.isActive);
    final total = Money.sum(active.map((m) => m.amount));
    return SectionCard(
      title: title,
      trailing: Text(
        '${Formatters.money(total)} / mes',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      child: Column(
        children: [
          for (final movement in movements)
            _FixedTile(
              movement: movement,
              category: categories[movement.categoryId],
            ),
        ],
      ),
    );
  }
}

class _FixedTile extends ConsumerWidget {
  const new({required this.movement, required this.category});

  final FixedMovement movement;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sign = movement.kind == TransactionKind.expense ? '-' : '+';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CategoryAvatar(category: category, size: 40),
      title: Text(movement.name),
      subtitle: Text(
        [
          'Cada día ${movement.dayOfMonth}',
          if (category != null) category!.name,
          if (!movement.isActive) 'Pausado',
        ].join(' · '),
      ),
      trailing: Text(
        '$sign${Formatters.money(movement.amount)}',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      onTap: () => showFormSheet<void>(
        context,
        FixedMovementFormSheet(movement: movement),
      ),
    );
  }
}

/// Borra un fijo previa confirmación. Los movimientos ya registrados se
/// conservan. Devuelve `true` si se eliminó.
Future<bool> deleteFixedMovement(
  BuildContext context,
  WidgetRef ref,
  FixedMovement movement,
) async {
  final delete = ref.read(deleteFixedMovementProvider);
  if (!await confirmDelete(context, 'este fijo')) return false;
  final result = await delete(movement.id);
  if (!context.mounted) return false;
  return showResult(context, result, success: 'Fijo eliminado');
}
