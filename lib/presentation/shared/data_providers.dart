import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/application/insights/financial_health.dart';
import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/domain/budgets/budget_evaluator.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/extra_payment.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/insights/cash_flow_calculator.dart';
import 'package:finance_app/domain/insights/spending_insights_analyzer.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/investments/portfolio_calculator.dart';
import 'package:finance_app/domain/savings/essential_expense_estimator.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/goal_progress_calculator.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/date_range.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/domain/wealth/net_worth_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Lecturas reactivas: cada provider observa un port y se actualiza solo
// cuando cambian los datos locales.

final currentMonthProvider = Provider<YearMonth>(
  (ref) => YearMonth.fromDate(ref.watch(clockProvider).now()),
);

/// Incluye archivadas: los movimientos antiguos necesitan su nombre.
final categoriesProvider = StreamProvider<List<Category>>(
  (ref) =>
      ref.watch(categoryRepositoryProvider).watchAll(includeArchived: true),
);

final monthTransactionsProvider =
    StreamProvider.family<List<Transaction>, YearMonth>(
      (ref, month) =>
          ref.watch(transactionRepositoryProvider).watchByPeriod(month.range),
    );

/// Movimientos de los últimos 30 días (categorías frecuentes).
final last30DaysTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final now = ref.watch(clockProvider).now();
  final today = DateTime(now.year, now.month, now.day);
  final range = DateRange(
    today.subtract(const Duration(days: 30)),
    today.add(const Duration(days: 1)),
  );
  return ref.watch(transactionRepositoryProvider).watchByPeriod(range);
});

final recentTransactionsProvider = StreamProvider<List<Transaction>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchRecent(limit: 20),
);

final budgetLinesProvider = StreamProvider.family<List<BudgetLine>, YearMonth>(
  (ref, month) => ref.watch(budgetRepositoryProvider).watchByMonth(month),
);

final assetsProvider = StreamProvider<List<Asset>>(
  (ref) => ref.watch(assetRepositoryProvider).watchAll(),
);

final debtsProvider = StreamProvider<List<Debt>>(
  (ref) => ref.watch(debtRepositoryProvider).watchAll(),
);

final investmentsProvider = StreamProvider<List<Investment>>(
  (ref) => ref.watch(investmentRepositoryProvider).watchAll(),
);

final goalsProvider = StreamProvider<List<SavingsGoal>>(
  (ref) => ref.watch(savingsGoalRepositoryProvider).watchAll(),
);

final contributionsProvider = StreamProvider<List<GoalContribution>>(
  (ref) => ref.watch(savingsGoalRepositoryProvider).watchContributions(),
);

final settingsProvider = StreamProvider<FinanceSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

final monthCashFlowProvider = FutureProvider.family<CashFlow, YearMonth>((
  ref,
  month,
) async {
  final transactions = ref.watch(monthTransactionsProvider(month).future);
  final categories = await ref.watch(categoriesProvider.future);
  return const CashFlowCalculator().calculate(
    await transactions,
    savingCategoryIds: {
      for (final c in categories)
        if (c.countsAsSaving) c.id,
    },
  );
});

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final month = ref.watch(currentMonthProvider);
  // Se suscriben todos antes del primer await para que cualquier cambio
  // recalcule el resumen.
  final monthTransactions = ref.watch(monthTransactionsProvider(month).future);
  final recent = ref.watch(recentTransactionsProvider.future);
  final categories = ref.watch(categoriesProvider.future);
  final budgetLines = ref.watch(budgetLinesProvider(month).future);
  final assets = ref.watch(assetsProvider.future);
  final investments = ref.watch(investmentsProvider.future);
  final debts = ref.watch(debtsProvider.future);
  final goals = ref.watch(goalsProvider.future);
  final contributions = ref.watch(contributionsProvider.future);
  final settings = ref.watch(settingsProvider.future);

  return const HomeSummaryBuilder().build(
    month: month,
    today: ref.watch(clockProvider).now(),
    monthTransactions: await monthTransactions,
    recentTransactions: await recent,
    categories: await categories,
    budgetLines: await budgetLines,
    assets: await assets,
    investments: await investments,
    debts: await debts,
    goals: await goals,
    contributions: await contributions,
    settings: await settings,
  );
});

final transactionsInRangeProvider =
    StreamProvider.family<List<Transaction>, DateRange>(
      (ref, range) =>
          ref.watch(transactionRepositoryProvider).watchByPeriod(range),
    );

final fixedMovementsProvider = StreamProvider<List<FixedMovement>>(
  (ref) => ref.watch(fixedMovementRepositoryProvider).watchAll(),
);

/// Ciclo de sueldo actual según el día de pago configurado.
final currentCycleProvider = FutureProvider<PayCycle>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return PayCycle.containing(
    ref.watch(clockProvider).now(),
    payday: settings.payday,
  );
});

final cycleSummaryProvider = FutureProvider<CycleSummary>((ref) async {
  final categories = ref.watch(categoriesProvider.future);
  final fixed = ref.watch(fixedMovementsProvider.future);
  final settings = ref.watch(settingsProvider.future);
  final cycle = await ref.watch(currentCycleProvider.future);
  final current = ref.watch(transactionsInRangeProvider(cycle.range).future);
  final previous = ref.watch(
    transactionsInRangeProvider(cycle.previous.range).future,
  );

  return const CycleSummaryBuilder().build(
    cycle: cycle,
    today: ref.watch(clockProvider).now(),
    cycleTransactions: await current,
    previousCycleTransactions: await previous,
    categories: await categories,
    fixedMovements: await fixed,
    settings: await settings,
  );
});

final financialHealthProvider = FutureProvider<FinancialHealth>((ref) async {
  final month = ref.watch(currentMonthProvider);
  final current = ref.watch(monthTransactionsProvider(month).future);
  final previous = ref.watch(monthTransactionsProvider(month.previous).future);
  final categories = ref.watch(categoriesProvider.future);
  final budgetLines = ref.watch(budgetLinesProvider(month).future);
  final assets = ref.watch(assetsProvider.future);
  final investments = ref.watch(investmentsProvider.future);
  final debts = ref.watch(debtsProvider.future);
  final goals = ref.watch(goalsProvider.future);
  final contributions = ref.watch(contributionsProvider.future);
  final settings = ref.watch(settingsProvider.future);

  return const FinancialHealthBuilder().build(
    month: month,
    today: ref.watch(clockProvider).now(),
    currentMonth: await current,
    previousMonth: await previous,
    categories: await categories,
    budgetLines: await budgetLines,
    assets: await assets,
    investments: await investments,
    debts: await debts,
    goals: await goals,
    contributions: await contributions,
    settings: await settings,
  );
});

final monthBudgetProvider = FutureProvider.family<MonthBudgetStatus, YearMonth>(
  (ref, month) async {
    final lines = ref.watch(budgetLinesProvider(month).future);
    final transactions = ref.watch(monthTransactionsProvider(month).future);
    final settings = await ref.watch(settingsProvider.future);
    return BudgetEvaluator(settings.thresholds).evaluate(
      period: month,
      lines: await lines,
      transactions: await transactions,
    );
  },
);

/// Gasto real del mes por categoría (para categorías sin presupuesto).
final monthSpendingProvider =
    FutureProvider.family<Map<String, Money>, YearMonth>((ref, month) async {
      final transactions = ref.watch(monthTransactionsProvider(month).future);
      final categories = await ref.watch(categoriesProvider.future);
      final breakdown = const SpendingInsightsAnalyzer().breakdown(
        await transactions,
        savingCategoryIds: {
          for (final c in categories)
            if (c.countsAsSaving) c.id,
        },
      );
      return {for (final c in breakdown) c.categoryId: c.amount};
    });

final netWorthProvider = FutureProvider<NetWorth>((ref) async {
  final assets = ref.watch(assetsProvider.future);
  final investments = ref.watch(investmentsProvider.future);
  final debts = ref.watch(debtsProvider.future);
  return const NetWorthCalculator().calculate(
    assets: await assets,
    investments: await investments,
    debts: await debts,
  );
});

final portfolioProvider = FutureProvider<PortfolioSummary>(
  (ref) async => const PortfolioCalculator().summarize(
    await ref.watch(investmentsProvider.future),
  ),
);

final goalProgressListProvider = FutureProvider<List<GoalProgressItem>>((
  ref,
) async {
  final goals = ref.watch(goalsProvider.future);
  final contributions = await ref.watch(contributionsProvider.future);
  final today = ref.watch(clockProvider).now();
  const calculator = GoalProgressCalculator();
  return [
    for (final goal in await goals)
      GoalProgressItem(
        goal: goal,
        progress: calculator.calculate(
          goal: goal,
          contributions: contributions,
          today: today,
        ),
      ),
  ];
});

/// Promedio de gastos esenciales de los últimos 3 meses completos.
final essentialExpensesSuggestionProvider = FutureProvider<Money>((ref) async {
  final current = ref.watch(currentMonthProvider);
  final months = [for (var i = 1; i <= 3; i++) current.addMonths(-i)];
  final pending = [
    for (final m in months) ref.watch(monthTransactionsProvider(m).future),
  ];
  return const EssentialExpenseEstimator().averageMonthly(
    transactions: [for (final p in pending) ...await p],
    months: months,
  );
});

final extraPaymentsProvider = FutureProvider.family<List<ExtraPayment>, String>(
  (ref, debtId) => ref.watch(debtRepositoryProvider).getExtraPayments(debtId),
);
