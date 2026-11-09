import 'package:finance_app/application/dashboard/daily_spending.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/cycles/pay_cycle_resolver.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Un ciclo con lo que sobró (o faltó) y lo acumulado hasta él.
final class CycleLedgerEntry {
  const new({
    required this.cycle,
    required this.result,
    required this.accumulated,
    required this.isCurrent,
  });

  final PayCycle cycle;

  /// Lo que quedó del ciclo (con el reconteo): positivo = sobró.
  final Money result;

  /// Suma de los ciclos hasta este, incluido.
  final Money accumulated;

  /// Es el ciclo en curso (su resultado aún cambia).
  final bool isCurrent;
}

/// "¿Cuánto dinero tengo en total?": lo que va del ciclo más lo que sobró
/// de los ciclos anteriores, ciclo a ciclo. No incluye lo que moviste a
/// metas o apartados (eso ya salió como aporte).
final class CycleLedger {
  const new({required this.entries});

  static const empty = CycleLedger(entries: []);

  /// Del más antiguo al más reciente.
  final List<CycleLedgerEntry> entries;

  bool get isEmpty => entries.isEmpty;

  /// Dinero total hoy: acumulado de todos los ciclos.
  Money get total => entries.isEmpty ? Money.zero : entries.last.accumulated;

  /// Lo que va del ciclo en curso.
  Money get current => entries
      .where((e) => e.isCurrent)
      .fold(Money.zero, (sum, e) => sum + e.result);

  /// Lo que traes de los ciclos que ya cerraron.
  Money get carried => total - current;

  /// Ciclos cerrados.
  Iterable<CycleLedgerEntry> get closed => entries.where((e) => !e.isCurrent);
}

final class CycleLedgerBuilder {
  const new();

  /// Ciclos que caben en un año de movimientos.
  static const maxCycles = 13;

  CycleLedger build({
    required PayCycleResolver resolver,
    required DateTime today,
    required List<Transaction> transactions,
    required Set<String> savingCategoryIds,
  }) {
    final records = const CycleHistoryBuilder().build(
      resolver: resolver,
      today: today,
      transactions: transactions,
      savingCategoryIds: savingCategoryIds,
      cycles: maxCycles,
    );
    var accumulated = Money.zero;
    return CycleLedger(
      entries: [
        // `records` va del ciclo actual hacia atrás.
        for (final (i, record) in records.indexed.toList().reversed)
          CycleLedgerEntry(
            cycle: record.cycle,
            result: record.result,
            accumulated: accumulated += record.result,
            isCurrent: i == 0,
          ),
      ],
    );
  }
}
