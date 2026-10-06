import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/domain/budgets/budget_line.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  const october = YearMonth(2026, 10);
  const food = 'seed-expense-food';

  HomeSummary build({
    List<Transaction> transactions = const [],
    List<BudgetLine> budget = const [],
    List<Debt> debts = const [],
    List<SavingsGoal> goals = const [],
  }) => const HomeSummaryBuilder().build(
    month: october,
    today: DateTime(2026, 10, 15),
    monthTransactions: transactions,
    recentTransactions: transactions,
    categories: DefaultCategories.all,
    budgetLines: budget,
    assets: const [],
    investments: const [],
    debts: debts,
    goals: goals,
    contributions: const [],
    settings: const FinanceSettings(),
  );

  BudgetLine foodBudget(int pesos) => BudgetLine(
    id: 'b1',
    period: october,
    categoryId: food,
    limit: Money.pesos(pesos),
  );

  group('semáforo', () {
    test('sin datos: verde con mensaje inicial', () {
      final status = build().status;
      expect(status.light, TrafficLight.ok);
      expect(status.reason, FinancialStatusReason.noData);
    });

    test('presupuesto al 90%: amarillo', () {
      final status = build(
        transactions: [
          income(5000000),
          expense(450000, category: food),
        ],
        budget: [foodBudget(500000)],
      ).status;
      expect(status.light, TrafficLight.warning);
      expect(status.reason, FinancialStatusReason.nearBudgetLimit);
      expect(status.usage, const Percentage.whole(90));
    });

    test('gastos mayores que ingresos dominan sobre un presupuesto sano', () {
      final status = build(
        transactions: [
          income(1000000),
          expense(100000, category: food),
          expense(1200000, category: 'seed-expense-housing'),
        ],
        budget: [foodBudget(500000)],
      ).status;
      expect(status.light, TrafficLight.critical);
      expect(status.reason, FinancialStatusReason.expensesOverIncome);
    });
  });

  test('la torta agrupa en "Otros" desde la quinta categoría', () {
    final slices = build(
      transactions: [
        for (final (i, c) in DefaultCategories.expenses.take(7).indexed)
          expense(100000 * (7 - i), category: c.id),
      ],
    ).spendingSlices;

    expect(slices, hasLength(HomeSummaryBuilder.maxSlices));
    expect(slices.first.category!.id, food);
    expect(slices.last.category, isNull);
    expect(slices.last.amount, const Money.pesos(600000));
  });

  test('incluye la proyección de deudas con condiciones', () {
    const loan = Debt(
      id: 'd1',
      name: 'Crédito',
      type: DebtType.bankLoan,
      originalAmount: Money.pesos(1000000),
      currentBalance: Money.pesos(600000),
      terms: LoanTerms(
        rate: InterestRate(
          rate: Percentage.zero,
          type: InterestRateType.effectiveMonthly,
        ),
        monthlyPayment: Money.pesos(200000),
      ),
    );
    final debt = build(debts: [loan]).debts.single;

    expect(debt.paidShare, const Percentage.whole(40));
    expect(debt.projection!.months, 3);
    expect(debt.projection!.payoffMonth, const YearMonth(2027, 1));
  });

  test('la meta principal es el fondo de emergencia', () {
    const travel = SavingsGoal(
      id: 'g1',
      name: 'Viaje',
      type: GoalType.travel,
      targetAmount: Money.pesos(1000000),
    );
    const emergency = SavingsGoal(
      id: 'g2',
      name: 'Fondo de emergencia',
      type: GoalType.emergency,
      targetAmount: Money.pesos(7500000),
    );

    expect(build(goals: [travel, emergency]).mainGoal!.goal, emergency);
  });
}
