import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Categorías para selección rápida: primero las más usadas recientemente,
/// completando con el orden por defecto.
final class FrequentCategories {
  const new();

  static const defaultLimit = 6;

  List<Category> select({
    required List<Category> categories,
    required List<Transaction> recent,
    required CategoryKind kind,
    int limit = defaultLimit,
  }) {
    final usage = <String, int>{};
    for (final t in recent) {
      usage.update(t.categoryId, (count) => count + 1, ifAbsent: () => 1);
    }
    final candidates =
        categories.where((c) => c.kind == kind && !c.isArchived).toList()
          ..sort((a, b) {
            final byUsage = (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0);
            return byUsage != 0 ? byUsage : a.sortOrder.compareTo(b.sortOrder);
          });
    return candidates.take(limit).toList();
  }
}
