import 'package:finance_app/domain/budgets/budget_evaluator.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/insights/cash_flow_calculator.dart';
import 'package:finance_app/domain/insights/insight.dart';
import 'package:finance_app/domain/insights/spending_insights_analyzer.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/goal_progress_calculator.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/domain/wealth/net_worth_calculator.dart';

/// Métricas individuales (sin "score" arbitrario) + observaciones.
final class FinancialHealth {
  const new({
    required this.month,
    required this.cashFlow,
    required this.netWorth,
    required this.budget,
    required this.spendingChange,
    required this.emergencyProgress,
    required this.goalsProgress,
    required this.breakdown,
    required this.insights,
  });

  final YearMonth month;
  final CashFlow cashFlow;
  final NetWorth netWorth;
  final MonthBudgetStatus budget;

  /// Variación del gasto real frente al mes anterior.
  final Percentage? spendingChange;
  final Percentage? emergencyProgress;

  /// Total ahorrado / total objetivo de todas las metas.
  final Percentage? goalsProgress;
  final List<CategorySpending> breakdown;
  final List<Insight> insights;
}

final class FinancialHealthBuilder {
  const new();

  FinancialHealth build({
    required YearMonth month,
    required DateTime today,
    required List<Transaction> currentMonth,
    required List<Transaction> previousMonth,
    required List<Category> categories,
    required List<BudgetLine> budgetLines,
    required List<Asset> assets,
    required List<Investment> investments,
    required List<Debt> debts,
    required List<SavingsGoal> goals,
    required List<GoalContribution> contributions,
    required FinanceSettings settings,
  }) {
    final savingIds = {
      for (final c in categories)
        if (c.countsAsSaving) c.id,
    };
    const cashFlowCalculator = CashFlowCalculator();
    final cashFlow = cashFlowCalculator.calculate(
      currentMonth,
      savingCategoryIds: savingIds,
    );
    final previous = cashFlowCalculator.calculate(
      previousMonth,
      savingCategoryIds: savingIds,
    );
    final budget = BudgetEvaluator(
      settings.thresholds,
    ).evaluate(period: month, lines: budgetLines, transactions: currentMonth);
    const analyzer = SpendingInsightsAnalyzer();

    const goalCalculator = GoalProgressCalculator();
    final progress = [
      for (final goal in goals)
        (
          goal: goal,
          progress: goalCalculator.calculate(
            goal: goal,
            contributions: contributions,
            today: today,
          ),
        ),
    ];
    final emergency = progress
        .where((p) => p.goal.type == GoalType.emergency)
        .firstOrNull;

    return FinancialHealth(
      month: month,
      cashFlow: cashFlow,
      netWorth: const NetWorthCalculator().calculate(
        assets: assets,
        investments: investments,
        debts: debts,
      ),
      budget: budget,
      spendingChange: Percentage.ratio(
        cashFlow.expenses - previous.expenses,
        previous.expenses,
      ),
      emergencyProgress: emergency?.progress.progress,
      goalsProgress: Percentage.ratio(
        Money.sum(progress.map((p) => p.progress.saved)),
        Money.sum(progress.map((p) => p.progress.target)),
      ),
      breakdown: analyzer.breakdown(currentMonth, savingCategoryIds: savingIds),
      insights: analyzer.analyze(
        current: currentMonth,
        previous: previousMonth,
        savingCategoryIds: savingIds,
        smallExpenseThreshold: settings.smallExpenseThreshold,
        budget: budget,
      ),
    );
  }
}
