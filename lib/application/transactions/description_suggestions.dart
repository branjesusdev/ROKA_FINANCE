import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Algo que ya anotaste antes, para no escribirlo de nuevo: al elegirlo se
/// llena la descripción y se selecciona su categoría.
final class DescriptionSuggestion {
  const new({
    required this.text,
    required this.categoryId,
    required this.count,
    this.lastAmount,
    this.isFixed = false,
  });

  final String text;
  final String categoryId;

  /// Veces que lo anotaste.
  final int count;
  final Money? lastAmount;

  /// Viene de un fijo (arriendo, internet…), no de un movimiento.
  final bool isFixed;
}

/// Sugerencias de descripción según lo que escribes. Lista corta: primero
/// lo que empieza igual, luego lo más usado y lo más reciente.
final class DescriptionSuggestions {
  const new();

  static const maxResults = 5;

  /// Letras mínimas para sugerir.
  static const minQueryLength = 1;

  List<DescriptionSuggestion> suggest({
    required String query,
    required TransactionKind kind,
    required Iterable<Transaction> history,
    required List<Category> categories,
    Iterable<FixedMovement> fixed = const [],
  }) {
    final q = normalize(query);
    if (q.length < minQueryLength) return const [];
    final usable = {
      for (final c in categories)
        if (!c.isArchived) c.id,
    };
    final groups = <String, _Group>{};
    final sorted = history.where((t) => t.kind == kind).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    for (final t in sorted) {
      final text = t.description?.trim();
      if (text == null || text.isEmpty || !usable.contains(t.categoryId)) {
        continue;
      }
      // La primera vez que aparece es la más reciente: manda su categoría.
      groups
              .putIfAbsent(
                normalize(text),
                () => _Group(text, t.categoryId, t.amount, t.date),
              )
              .count +=
          1;
    }
    for (final f in fixed.where((f) => f.kind == kind)) {
      if (!usable.contains(f.categoryId)) continue;
      groups.putIfAbsent(
        normalize(f.name),
        () => _Group(f.name, f.categoryId, f.amount, null, isFixed: true),
      );
    }
    final matches = groups.entries.where((e) {
      final key = e.key;
      return key.startsWith(q) || key.contains(' $q');
    }).toList();
    // Los fijos (sin fecha) van después de lo anotado.
    final never = DateTime.fromMillisecondsSinceEpoch(0);
    matches.sort((a, b) {
      final prefix = (b.key.startsWith(q) ? 1 : 0).compareTo(
        a.key.startsWith(q) ? 1 : 0,
      );
      if (prefix != 0) return prefix;
      final count = b.value.count.compareTo(a.value.count);
      if (count != 0) return count;
      return (b.value.last ?? never).compareTo(a.value.last ?? never);
    });
    return [
      for (final MapEntry(value: g) in matches.take(maxResults))
        DescriptionSuggestion(
          text: g.text,
          categoryId: g.categoryId,
          count: g.count,
          lastAmount: g.amount,
          isFixed: g.isFixed,
        ),
    ];
  }

  /// Minúsculas, sin tildes ni espacios repetidos.
  static String normalize(String text) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    final buffer = StringBuffer();
    for (final char in text.trim().toLowerCase().split('')) {
      final i = from.indexOf(char);
      buffer.write(i < 0 ? char : to[i]);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }
}

final class _Group {
  new(
    this.text,
    this.categoryId,
    this.amount,
    this.last, {
    this.isFixed = false,
  });

  final String text;
  final String categoryId;
  final Money amount;
  final DateTime? last;
  final bool isFixed;
  int count = 0;
}
