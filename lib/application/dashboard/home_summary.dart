import 'package:finance_app/domain/budgets/budget_evaluator.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/loan_projector.dart';
import 'package:finance_app/domain/insights/cash_flow_calculator.dart';
import 'package:finance_app/domain/insights/spending_insights_analyzer.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/goal_progress_calculator.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/savings/savings_target_evaluator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/domain/wealth/net_worth_calculator.dart';

/// Motivo principal del semáforo del Home.
enum FinancialStatusReason {
  noData,
  withinLimits,
  nearBudgetLimit,
  overBudget,
  expensesNearIncome,
  expensesOverIncome,
}

final class FinancialStatus {
  const new({required this.light, required this.reason, this.usage});

  final TrafficLight light;
  final FinancialStatusReason reason;

  /// % de presupuesto usado o de gasto sobre ingreso, según [reason].
  final Percentage? usage;
}

/// Porción del gráfico de gastos. `category == null` agrupa "Otros".
final class CategorySlice {
  const new({
    required this.category,
    required this.amount,
    required this.share,
  });

  final Category? category;
  final Money amount;
  final Percentage share;
}

final class DebtProgress {
  const new({required this.debt, this.projection});

  final Debt debt;

  /// `null` si la deuda no tiene condiciones de crédito.
  final LoanProjection? projection;

  Percentage? get paidShare =>
      Percentage.ratio(debt.paidAmount, debt.originalAmount);
}

final class GoalProgressItem {
  const new({required this.goal, required this.progress});

  final SavingsGoal goal;
  final GoalProgress progress;
}

final class TransactionItem {
  const new({required this.transaction, required this.category});

  final Transaction transaction;
  final Category? category;
}

final class HomeSummary {
  const new({
    required this.month,
    required this.cashFlow,
    required this.netWorth,
    required this.budget,
    required this.savings,
    required this.status,
    required this.spendingSlices,
    required this.recentExpenses,
    required this.debts,
    required this.mainGoal,
  });

  final YearMonth month;
  final CashFlow cashFlow;
  final NetWorth netWorth;
  final MonthBudgetStatus budget;
  final SavingsStatus savings;
  final FinancialStatus status;
  final List<CategorySlice> spendingSlices;
  final List<TransactionItem> recentExpenses;
  final List<DebtProgress> debts;
  final GoalProgressItem? mainGoal;
}

/// Compone el resumen del Home a partir de los datos registrados.
final class HomeSummaryBuilder {
  const new();

  static const maxSlices = 5;
  static const maxRecent = 5;

  HomeSummary build({
    required YearMonth month,
    required DateTime today,
    required List<Transaction> monthTransactions,
    required List<Transaction> recentTransactions,
    required List<Category> categories,
    required List<BudgetLine> budgetLines,
    required List<Asset> assets,
    required List<Investment> investments,
    required List<Debt> debts,
    required List<SavingsGoal> goals,
    required List<GoalContribution> contributions,
    required FinanceSettings settings,
  }) {
    final byId = {for (final c in categories) c.id: c};
    final savingIds = {
      for (final c in categories)
        if (c.countsAsSaving) c.id,
    };
    final cashFlow = const CashFlowCalculator().calculate(
      monthTransactions,
      savingCategoryIds: savingIds,
    );
    final budget = BudgetEvaluator(settings.thresholds).evaluate(
      period: month,
      lines: budgetLines,
      transactions: monthTransactions,
    );

    return HomeSummary(
      month: month,
      cashFlow: cashFlow,
      netWorth: const NetWorthCalculator().calculate(
        assets: assets,
        investments: investments,
        debts: debts,
      ),
      budget: budget,
      savings: const SavingsTargetEvaluator().evaluate(
        income: cashFlow.income,
        actualSavings: cashFlow.savings,
        targetRate: settings.savingsTargetRate,
      ),
      status: _status(cashFlow, budget, settings),
      spendingSlices: _slices(monthTransactions, savingIds, byId),
      recentExpenses: [
        for (final t
            in recentTransactions.where((t) => t.isExpense).take(maxRecent))
          TransactionItem(transaction: t, category: byId[t.categoryId]),
      ],
      debts: [
        for (final debt in debts.where((d) => !d.isPaidOff))
          DebtProgress(
            debt: debt,
            projection: debt.terms == null
                ? null
                : const LoanProjector().project(
                    balance: debt.currentBalance,
                    terms: debt.terms!,
                    firstPaymentMonth: month.next,
                  ),
          ),
      ],
      mainGoal: _mainGoal(goals, contributions, today),
    );
  }

  FinancialStatus _status(
    CashFlow cashFlow,
    MonthBudgetStatus budget,
    FinanceSettings settings,
  ) {
    final candidates = <FinancialStatus>[];
    final budgetUsage = budget.total.usage;
    if (budget.hasBudget && budgetUsage != null) {
      final light = budget.total.light;
      candidates.add(
        FinancialStatus(
          light: light,
          usage: budgetUsage,
          reason: switch (light) {
            TrafficLight.ok => FinancialStatusReason.withinLimits,
            TrafficLight.warning => FinancialStatusReason.nearBudgetLimit,
            TrafficLight.critical => FinancialStatusReason.overBudget,
          },
        ),
      );
    }
    final expenseRatio = cashFlow.expenseRatio;
    if (expenseRatio != null) {
      final light = settings.thresholds.classifyUsage(expenseRatio);
      candidates.add(
        FinancialStatus(
          light: light,
          usage: expenseRatio,
          reason: switch (light) {
            TrafficLight.ok => FinancialStatusReason.withinLimits,
            TrafficLight.warning => FinancialStatusReason.expensesNearIncome,
            TrafficLight.critical => FinancialStatusReason.expensesOverIncome,
          },
        ),
      );
    }
    if (candidates.isEmpty) {
      return const FinancialStatus(
        light: TrafficLight.ok,
        reason: FinancialStatusReason.noData,
      );
    }
    return candidates.reduce(
      (worst, next) => next.light.index > worst.light.index ? next : worst,
    );
  }

  List<CategorySlice> _slices(
    List<Transaction> transactions,
    Set<String> savingIds,
    Map<String, Category> byId,
  ) {
    final breakdown = const SpendingInsightsAnalyzer().breakdown(
      transactions,
      savingCategoryIds: savingIds,
    );
    final top = breakdown.take(maxSlices - 1).toList();
    final rest = breakdown.skip(maxSlices - 1).toList();
    final restAmount = Money.sum(rest.map((c) => c.amount));
    final total = Money.sum(breakdown.map((c) => c.amount));
    return [
      for (final c in top)
        CategorySlice(
          category: byId[c.categoryId],
          amount: c.amount,
          share: c.share,
        ),
      if (rest.length == 1)
        CategorySlice(
          category: byId[rest.single.categoryId],
          amount: restAmount,
          share: rest.single.share,
        )
      else if (rest.isNotEmpty)
        CategorySlice(
          category: null,
          amount: restAmount,
          share: Percentage.ratio(restAmount, total) ?? Percentage.zero,
        ),
    ];
  }

  /// Prioriza el fondo de emergencia; si no, la primera meta sin cumplir.
  GoalProgressItem? _mainGoal(
    List<SavingsGoal> goals,
    List<GoalContribution> contributions,
    DateTime today,
  ) {
    const calculator = GoalProgressCalculator();
    final items = [
      for (final goal in goals)
        GoalProgressItem(
          goal: goal,
          progress: calculator.calculate(
            goal: goal,
            contributions: contributions,
            today: today,
          ),
        ),
    ];
    return items.where((i) => i.goal.type == GoalType.emergency).firstOrNull ??
        items.where((i) => !i.progress.isCompleted).firstOrNull;
  }
}
