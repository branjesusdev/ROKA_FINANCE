import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/presentation/fixed/fixed_movements_screen.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fijos que faltan en el ciclo y cuánto quedaría después de pagarlos.
class UpcomingFixedCard extends ConsumerWidget {
  const new({required this.summary, super.key});

  final CycleSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final upcoming = summary.upcomingFixed.upcoming;
    final hasFixed =
        (ref.watch(fixedMovementsProvider).value ?? const []).isNotEmpty;

    return SectionCard(
      title: 'Fijos del mes',
      trailing: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const FixedMovementsScreen()),
        ),
        child: Text(hasFixed ? 'Gestionar' : 'Agregar'),
      ),
      child: !hasFixed
          ? const Text(
              'Arriendo, colegio, cuota alimentaria, entrenos, crédito o tu '
              'sueldo: agrégalos una vez y se registran solos cada mes.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (upcoming.isEmpty)
                  const Text('Todos los fijos de este ciclo ya se registraron.')
                else
                  for (final item in upcoming)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        item.movement.isExpense
                            ? Icons.event_repeat
                            : Icons.savings_outlined,
                      ),
                      title: Text(item.movement.name),
                      subtitle: Text(
                        '${Formatters.shortDate(item.date)} · '
                        '${categories[item.movement.categoryId]?.name ?? ''}',
                      ),
                      trailing: Text(
                        '${item.movement.isExpense ? '-' : '+'}'
                        '${Formatters.money(item.movement.amount)}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                if (upcoming.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    'Después de los fijos te quedarían '
                    '${Formatters.money(summary.leftAfterFixed)}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: summary.leftAfterFixed.isNegative
                          ? theme.colorScheme.error
                          : null,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
