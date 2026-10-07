import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/cycles/pay_cycle_resolver.dart';
import 'package:finance_app/domain/insights/cash_flow_calculator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Gasto de un día, separado en día a día y lo demás (fijos, mercado…).
final class DaySpending {
  const new({
    required this.date,
    required this.dayToDay,
    required this.planned,
    required this.transactions,
  });

  final DateTime date;

  /// Almuerzos, transporte, antojos: lo que mide el tope diario.
  final Money dayToDay;

  /// Fijos, mercado, servicios… (planeados por mes). Sin ahorro ni cuadres.
  final Money planned;

  /// Gastos del día, del más reciente al más antiguo.
  final List<Transaction> transactions;

  Money get total => dayToDay + planned;
}

/// Serie diaria del ciclo (desde el inicio hasta hoy).
final class DailySpendingSeries {
  const new({required this.days, required this.cap});

  final List<DaySpending> days;

  /// Tope diario actual (`null` sin tope).
  final Money? cap;

  /// Promedio del día a día.
  Money get averageDayToDay => days.isEmpty
      ? Money.zero
      : Money.sum(days.map((d) => d.dayToDay)).divide(days.length);

  int get daysOverCap {
    final limit = cap;
    if (limit == null) return 0;
    return days.where((d) => d.dayToDay > limit).length;
  }

  Money get maxTotal =>
      days.fold(Money.zero, (max, d) => d.total > max ? d.total : max);
}

final class DailySpendingBuilder {
  const new();

  DailySpendingSeries build({
    required PayCycle cycle,
    required DateTime today,
    required List<Transaction> transactions,
    required Set<String> savingCategoryIds,
    Money? cap,
  }) {
    final last = DateTime(today.year, today.month, today.day);
    final end = last.isBefore(cycle.lastDay) ? last : cycle.lastDay;
    final days = <DaySpending>[];
    for (
      var day = cycle.start;
      !day.isAfter(end);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final ofDay = transactions
          .where(
            (t) =>
                t.isExpense &&
                t.date.year == day.year &&
                t.date.month == day.month &&
                t.date.day == day.day,
          )
          .toList();
      days.add(
        DaySpending(
          date: day,
          dayToDay: Money.sum(
            ofDay
                .where(
                  (t) => CycleSummaryBuilder.isDayToDay(t, savingCategoryIds),
                )
                .map((t) => t.amount),
          ),
          planned: Money.sum(
            ofDay
                .where(
                  (t) =>
                      !CycleSummaryBuilder.isDayToDay(t, savingCategoryIds) &&
                      !savingCategoryIds.contains(t.categoryId) &&
                      t.categoryId != DefaultCategories.untracked.id,
                )
                .map((t) => t.amount),
          ),
          transactions: ofDay,
        ),
      );
    }
    return DailySpendingSeries(days: days, cap: cap);
  }
}

/// Resumen de un ciclo cerrado (o el actual) para el histórico.
final class CycleRecord {
  const new({
    required this.cycle,
    required this.income,
    required this.spent,
    required this.untracked,
    required this.result,
  });

  final PayCycle cycle;
  final Money income;

  /// Lo que salió en total (gastos + ahorro).
  final Money spent;

  /// Gastos sin registrar descubiertos al cuadrar.
  final Money untracked;

  /// Lo que quedó: positivo = sobrante (ahorro), negativo = déficit.
  final Money result;
}

/// Últimos ciclos, del más reciente al más antiguo, para comparar y
/// mejorar el siguiente.
final class CycleHistoryBuilder {
  const new();

  static const defaultCycles = 6;

  /// Días hacia atrás que cubren [defaultCycles] ciclos (con margen).
  static const lookbackDays =
      defaultCycles * 31 + PayCycleResolver.lookbackDays;

  List<CycleRecord> build({
    required PayCycleResolver resolver,
    required DateTime today,
    required List<Transaction> transactions,
    required Set<String> savingCategoryIds,
    int cycles = defaultCycles,
  }) {
    final records = <CycleRecord>[];
    var cycle = resolver.containing(today);
    for (var i = 0; i < cycles; i++) {
      final inCycle = transactions
          .where((t) => cycle.contains(t.date))
          .toList();
      if (inCycle.isEmpty && i > 0) break;
      final flow = const CashFlowCalculator().calculate(
        inCycle,
        savingCategoryIds: savingCategoryIds,
      );
      final spent = flow.expenses + flow.savingContributions;
      records.add(
        CycleRecord(
          cycle: cycle,
          income: flow.income,
          spent: spent,
          untracked: Money.sum(
            inCycle
                .where(
                  (t) =>
                      t.isExpense &&
                      t.categoryId == DefaultCategories.untracked.id,
                )
                .map((t) => t.amount),
          ),
          result: flow.adjustments + flow.income - spent,
        ),
      );
      cycle = resolver.previousOf(cycle);
    }
    return records;
  }
}
