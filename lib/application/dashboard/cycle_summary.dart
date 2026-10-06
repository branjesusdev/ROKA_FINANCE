import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/insights/cash_flow_calculator.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Total de una categoría dentro del ciclo.
final class CategoryTotal {
  const new({
    required this.category,
    required this.amount,
    required this.share,
    required this.count,
  });

  final Category? category;
  final Money amount;

  /// Participación sobre el total del mismo tipo (gastos o ingresos).
  final Percentage share;
  final int count;
}

/// "¿Cuánto me queda de mi sueldo?" para el ciclo actual (día de pago →
/// día anterior al siguiente pago). Independiente del patrimonio.
final class CycleSummary {
  const new({
    required this.cycle,
    required this.today,
    required this.cashFlow,
    required this.expenseTotals,
    required this.incomeTotals,
    required this.upcomingFixed,
    required this.previousLeft,
    this.usageLight,
  });

  final PayCycle cycle;
  final DateTime today;
  final CashFlow cashFlow;

  /// De mayor a menor.
  final List<CategoryTotal> expenseTotals;
  final List<CategoryTotal> incomeTotals;

  /// Fijos que aún no llegan en este ciclo.
  final FixedSchedule upcomingFixed;

  /// Lo que quedó al cerrar el ciclo anterior (`null` sin datos).
  final Money? previousLeft;

  /// Semáforo de gasto sobre ingreso. `null` si no hay ingresos.
  final TrafficLight? usageLight;

  Money get income => cashFlow.income;

  /// Gastos reales + aportes a ahorro/inversión (dinero que salió).
  Money get outflow => cashFlow.expenses + cashFlow.savingContributions;

  /// Lo que queda hoy en la billetera del ciclo.
  Money get left => income - outflow;

  /// Lo que quedaría al pagar los fijos pendientes (y recibir los
  /// ingresos fijos pendientes).
  Money get leftAfterFixed =>
      left - upcomingFixed.upcomingExpenses + upcomingFixed.upcomingIncome;

  int get daysLeft => cycle.daysLeft(today);

  /// Promedio diario disponible para lo que resta del ciclo.
  Money? get dailyAllowance {
    final days = daysLeft;
    if (days == 0 || !leftAfterFixed.isPositive) return null;
    return leftAfterFixed.divide(days);
  }

  /// Porcentaje del ingreso ya gastado.
  Percentage? get spentShare => Percentage.ratio(outflow, income);

  /// Diferencia con el ciclo anterior (positivo = mejor que antes).
  Money? get leftVsPrevious =>
      previousLeft == null ? null : left - previousLeft!;
}

final class CycleSummaryBuilder {
  const new();

  CycleSummary build({
    required PayCycle cycle,
    required DateTime today,
    required List<Transaction> cycleTransactions,
    required List<Transaction> previousCycleTransactions,
    required List<Category> categories,
    required List<FixedMovement> fixedMovements,
    required FinanceSettings settings,
  }) {
    final savingIds = {
      for (final c in categories)
        if (c.countsAsSaving) c.id,
    };
    const calculator = CashFlowCalculator();
    final cashFlow = calculator.calculate(
      cycleTransactions,
      savingCategoryIds: savingIds,
    );
    final previous = calculator.calculate(
      previousCycleTransactions,
      savingCategoryIds: savingIds,
    );
    final byId = {for (final c in categories) c.id: c};
    final outflow = cashFlow.expenses + cashFlow.savingContributions;
    final usage = Percentage.ratio(outflow, cashFlow.income);

    return CycleSummary(
      cycle: cycle,
      today: today,
      cashFlow: cashFlow,
      expenseTotals: _totals(cycleTransactions.where((t) => t.isExpense), byId),
      incomeTotals: _totals(cycleTransactions.where((t) => t.isIncome), byId),
      upcomingFixed: const FixedMovementScheduler().schedule(
        movements: fixedMovements,
        cycle: cycle,
        today: today,
      ),
      previousLeft: previousCycleTransactions.isEmpty
          ? null
          : previous.income - previous.expenses - previous.savingContributions,
      usageLight: usage == null
          ? null
          : settings.thresholds.classifyUsage(usage),
    );
  }

  List<CategoryTotal> _totals(
    Iterable<Transaction> transactions,
    Map<String, Category> byId,
  ) {
    final amounts = <String, Money>{};
    final counts = <String, int>{};
    for (final t in transactions) {
      amounts.update(
        t.categoryId,
        (a) => a + t.amount,
        ifAbsent: () => t.amount,
      );
      counts.update(t.categoryId, (c) => c + 1, ifAbsent: () => 1);
    }
    final total = Money.sum(amounts.values);
    return [
      for (final MapEntry(key: id, value: amount) in amounts.entries)
        CategoryTotal(
          category: byId[id],
          amount: amount,
          share: Percentage.ratio(amount, total) ?? Percentage.zero,
          count: counts[id]!,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
  }
}
