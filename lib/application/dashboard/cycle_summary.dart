import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/daily_spending_cap.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/insights/cash_flow_calculator.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/provisions/provision_planner.dart';
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
    required this.savingsTarget,
    this.monthlyFixedExpenses = Money.zero,
    this.previousCycle,
    this.usageLight,
    this.dailyCap,
    this.provisionPlan = ProvisionPlan.empty,
  });

  final PayCycle cycle;
  final DateTime today;
  final CashFlow cashFlow;

  /// De mayor a menor.
  final List<CategoryTotal> expenseTotals;
  final List<CategoryTotal> incomeTotals;

  /// Fijos que aún no llegan en este ciclo.
  final FixedSchedule upcomingFixed;

  /// Lo que quedó al cerrar el ciclo anterior (`null` sin datos). Al
  /// empezar un ciclo nuevo, ese sobrante cuenta como ahorro.
  final Money? previousLeft;

  final PayCycle? previousCycle;

  /// Ahorro de referencia del ciclo (% del ingreso configurado).
  final Money savingsTarget;

  /// Total de los gastos fijos activos de un mes (para apartarlos al
  /// recibir el sueldo).
  final Money monthlyFixedExpenses;

  /// Tope del gasto del día a día. `null` si el ciclo ya terminó.
  final DailySpendingCap? dailyCap;

  /// Semáforo de gasto sobre ingreso. `null` si no hay ingresos.
  final TrafficLight? usageLight;

  /// Pagos que no son mensuales (SOAT, matrícula…): cuánto apartar.
  final ProvisionPlan provisionPlan;

  Money get income => cashFlow.income;

  /// Gastos reales + aportes a ahorro/inversión (dinero que salió).
  Money get outflow => cashFlow.expenses + cashFlow.savingContributions;

  /// Lo que queda hoy en la billetera del ciclo (incluye el saldo que
  /// tenías al cuadrar).
  Money get left => cashFlow.adjustments + income - outflow;

  /// Gastos que no se anotaron y salieron al cuadrar el saldo.
  Money get untracked => Money.sum(
    expenseTotals
        .where((t) => t.category?.id == DefaultCategories.untracked.id)
        .map((t) => t.amount),
  );

  /// Lo que falta para cubrir los fijos hasta el próximo sueldo (`null` si
  /// alcanza).
  Money? get deficit => leftAfterFixed.isNegative ? leftAfterFixed.abs : null;

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
    List<BudgetLine> budgetLines = const [],
    List<Provision> provisions = const [],
    List<Transaction> provisionTransactions = const [],
    PayCycle? previousCycle,
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
    final upcoming = const FixedMovementScheduler().schedule(
      movements: fixedMovements,
      cycle: cycle,
      today: today,
      cycleTransactions: cycleTransactions,
    );
    final savingsTarget = cashFlow.income.applyPercentage(
      settings.savingsTargetRate,
    );
    final provisionPlan = const ProvisionPlanner().plan(
      provisions: provisions,
      linked: provisionTransactions,
      cycle: cycle,
      today: today,
    );
    // Lo apartado para pagos no mensuales no cuenta para la meta de ahorro.
    final savedThisCycle =
        cashFlow.savingContributions - provisionPlan.setAsideThisCycle;
    final leftAfterFixed =
        cashFlow.adjustments +
        cashFlow.income -
        outflow -
        upcoming.upcomingExpenses +
        upcoming.upcomingIncome;

    return CycleSummary(
      cycle: cycle,
      today: today,
      cashFlow: cashFlow,
      expenseTotals: _totals(cycleTransactions.where((t) => t.isExpense), byId),
      incomeTotals: _totals(cycleTransactions.where((t) => t.isIncome), byId),
      upcomingFixed: upcoming,
      previousCycle: previousCycle,
      savingsTarget: savingsTarget,
      monthlyFixedExpenses: Money.sum(
        fixedMovements
            .where((m) => m.isActive && m.isExpense)
            .map((m) => m.amount),
      ),
      dailyCap: const DailySpendingCapCalculator().calculate(
        available: leftAfterFixed,
        daysLeft: cycle.daysLeft(today),
        spentToday: _dayToDaySpentOn(today, cycleTransactions, savingIds),
        monthlyReserve:
            _monthlyReserve(
              budgetLines,
              cycleTransactions,
              upcoming.upcomingExpensesByCategory,
            ) +
            _kidsReserve(settings, cycleTransactions) +
            provisionPlan.pendingThisCycle,
        savingsReserve: (savingsTarget - savedThisCycle).max(Money.zero),
        thresholds: settings.thresholds,
      ),
      previousLeft: previousCycleTransactions.isEmpty
          ? null
          : previous.adjustments +
                previous.income -
                previous.expenses -
                previous.savingContributions,
      usageLight: usage == null
          ? null
          : settings.thresholds.classifyUsage(usage),
      provisionPlan: provisionPlan,
    );
  }

  /// Lo que falta del apartado mensual para imprevistos de los niños
  /// (descontando lo ya gastado en Hijos/Familia este ciclo).
  Money _kidsReserve(FinanceSettings settings, List<Transaction> transactions) {
    if (!settings.hasDependents) return Money.zero;
    final spent = Money.sum(
      transactions
          .where((t) => t.isExpense && t.categoryId == familyCategoryId)
          .map((t) => t.amount),
    );
    return (settings.kidsMonthlyBuffer - spent).max(Money.zero);
  }

  static const familyCategoryId = 'seed-expense-family';

  /// Gasto del día a día: ni ahorro ni categorías que se planean por mes.
  static bool isDayToDay(Transaction t, Set<String> savingIds) =>
      t.isExpense &&
      !savingIds.contains(t.categoryId) &&
      !DefaultCategories.monthlyPlannedIds.contains(t.categoryId);

  Money _dayToDaySpentOn(
    DateTime today,
    List<Transaction> transactions,
    Set<String> savingIds,
  ) => Money.sum(
    transactions
        .where(
          (t) =>
              isDayToDay(t, savingIds) &&
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .map((t) => t.amount),
  );

  /// Presupuesto que falta gastar en categorías del mes (mercado,
  /// servicios…), sin contar lo que ya cubren los fijos pendientes.
  Money _monthlyReserve(
    List<BudgetLine> lines,
    List<Transaction> transactions,
    Map<String, Money> upcomingFixedByCategory,
  ) {
    var reserve = Money.zero;
    for (final line in lines) {
      if (!DefaultCategories.monthlyPlannedIds.contains(line.categoryId)) {
        continue;
      }
      final spent = Money.sum(
        transactions
            .where((t) => t.isExpense && t.categoryId == line.categoryId)
            .map((t) => t.amount),
      );
      final pendingFixed =
          upcomingFixedByCategory[line.categoryId] ?? Money.zero;
      reserve += (line.limit - spent - pendingFixed).max(Money.zero);
    }
    return reserve;
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
