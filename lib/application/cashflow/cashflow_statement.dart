import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/cycles/pay_cycle_resolver.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/insights/cash_flow_calculator.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/asset.dart';

/// Una línea del balance: un bien o una deuda con lo que mueve al mes.
final class CashflowItem {
  const new({required this.name, required this.value, required this.monthly});

  final String name;

  /// Valor del bien o saldo de la deuda.
  final Money value;

  /// Lo que pone (+) o saca (−) de tu bolsillo cada mes.
  final Money monthly;
}

/// Tus finanzas como el tablero de *Cashflow* (Padre Rico, Padre Pobre):
/// estado de resultados (ingresos − gastos = flujo de caja del mes) y
/// balance (activos que te pagan vs. lo que te saca dinero). Sales de la
/// "carrera de la rata" cuando el ingreso pasivo cubre los gastos.
final class CashflowStatement {
  const new({
    required this.salary,
    required this.otherIncome,
    required this.passiveIncome,
    required this.expenses,
    required this.debtPayments,
    required this.cyclesUsed,
    this.incomeAssets = const [],
    this.costlyAssets = const [],
    this.savings = Money.zero,
    this.investments = const [],
    this.liabilities = const [],
  });

  /// Sueldo promedio por ciclo (ingreso activo: trabajas por él).
  final Money salary;

  /// Otros ingresos regulares que no vienen de tus activos.
  final Money otherIncome;

  /// Lo que te pagan tus activos cada mes sin trabajar (arriendos,
  /// utilidades), según lo que escribiste en Patrimonio.
  final Money passiveIncome;

  /// Gasto promedio por ciclo (sin ahorro ni inversión).
  final Money expenses;

  /// Cuotas mensuales de tus deudas (ya están dentro de [expenses]).
  final Money debtPayments;

  /// Ciclos cerrados promediados. 0 = estimado con los fijos.
  final int cyclesUsed;

  /// Bienes que ponen dinero en tu bolsillo cada mes.
  final List<CashflowItem> incomeAssets;

  /// Bienes que te cuestan cada mes (para Padre Rico, pasivos).
  final List<CashflowItem> costlyAssets;

  /// Efectivo y cuentas.
  final Money savings;

  final List<CashflowItem> investments;

  /// Deudas con saldo y su cuota.
  final List<CashflowItem> liabilities;

  Money get totalIncome => salary + otherIncome + passiveIncome;

  /// Flujo de caja del mes: lo que te sobra (o falta) cada mes.
  Money get cashflow => totalIncome - expenses;

  /// Cuánto de tus gastos cubre el ingreso pasivo (`null` sin gastos).
  Percentage? get freedom => Percentage.ratio(passiveIncome, expenses);

  /// Ingreso pasivo mensual que falta para salir de la carrera de la rata.
  Money get passiveGap => (expenses - passiveIncome).max(Money.zero);

  bool get outOfRatRace => expenses.isPositive && !passiveGap.isPositive;

  bool get isEstimate => cyclesUsed == 0;

  /// Mueve una carta: compra un activo o un capricho y mira cómo cambia tu
  /// tablero (simulación: no registra nada).
  CashflowOutcome play(CashflowCard card) {
    final passive = passiveIncome + card.monthlyIncome;
    final spend = expenses + card.monthlyCost;
    final after = CashflowStatement(
      salary: salary,
      otherIncome: otherIncome,
      passiveIncome: passive,
      expenses: spend,
      debtPayments: debtPayments,
      cyclesUsed: cyclesUsed,
    );
    final net = card.monthlyIncome - card.monthlyCost;
    return CashflowOutcome(
      before: this,
      after: after,
      paybackMonths: card.upfront.isPositive && net.isPositive
          ? _monthsToCover(card.upfront, net)
          : null,
      monthsOfCashflow: card.upfront.isPositive && cashflow.isPositive
          ? _monthsToCover(card.upfront, cashflow)
          : null,
    );
  }

  static int _monthsToCover(Money amount, Money perMonth) =>
      (amount.cents / perMonth.cents).ceil();
}

/// Una carta del juego: una oportunidad (activo que paga) o un capricho
/// (cosa que cuesta).
final class CashflowCard {
  const new({
    required this.kind,
    this.upfront = Money.zero,
    this.monthlyIncome = Money.zero,
    this.monthlyCost = Money.zero,
  });

  final CashflowCardKind kind;

  /// Lo que pagas de entrada.
  final Money upfront;

  /// Lo que te paga cada mes (arriendo, utilidades…).
  final Money monthlyIncome;

  /// Lo que te cuesta cada mes (cuota, mantenimiento, administración…).
  final Money monthlyCost;
}

enum CashflowCardKind {
  /// Activo: pone dinero en tu bolsillo.
  opportunity,

  /// Capricho a cuotas: saca dinero de tu bolsillo.
  doodad,
}

/// Cómo queda el tablero después de jugar una carta.
final class CashflowOutcome {
  const new({
    required this.before,
    required this.after,
    this.paybackMonths,
    this.monthsOfCashflow,
  });

  final CashflowStatement before;
  final CashflowStatement after;

  /// Meses en que el activo devuelve lo que pagaste de entrada.
  final int? paybackMonths;

  /// Meses de tu flujo de caja actual que se van en la entrada.
  final int? monthsOfCashflow;

  Money get cashflowChange => after.cashflow - before.cashflow;
}

/// Arma el tablero con tus ciclos cerrados (promedio) y tu patrimonio.
final class CashflowStatementBuilder {
  const new();

  /// Ciclos cerrados que se promedian.
  static const cycles = 3;

  CashflowStatement build({
    required PayCycleResolver resolver,
    required DateTime today,
    required List<Transaction> transactions,
    required Set<String> savingCategoryIds,
    required Set<String> extraordinaryCategoryIds,
    required List<Asset> assets,
    required List<Debt> debts,
    required List<Investment> investments,
    required Money monthlyFixedExpenses,
  }) {
    final passive = Money.sum(assets.map((a) => a.monthlyIncome));
    // Los ingresos que no llegan cada mes no cuentan como flujo mensual.
    final regular = transactions
        .where((t) => !extraordinaryCategoryIds.contains(t.categoryId))
        .toList();
    final closed = <PayCycle>[];
    var cycle = resolver.containing(today);
    for (var i = 0; i < cycles; i++) {
      cycle = resolver.previousOf(cycle);
      if (!regular.any((t) => cycle.contains(t.date))) break;
      closed.add(cycle);
    }

    Money salary;
    Money other;
    Money expenses;
    if (closed.isEmpty) {
      // Sin ciclos cerrados: el ciclo actual y los fijos como estimado.
      final current = resolver.containing(today);
      final inCycle = regular.where((t) => current.contains(t.date));
      salary = _salary(inCycle);
      other = _income(inCycle) - salary;
      expenses = monthlyFixedExpenses;
    } else {
      final inClosed = regular
          .where((t) => closed.any((c) => c.contains(t.date)))
          .toList();
      final flow = const CashFlowCalculator().calculate(
        inClosed,
        savingCategoryIds: savingCategoryIds,
      );
      salary = _salary(inClosed).divide(closed.length);
      other = flow.income.divide(closed.length) - salary;
      expenses = flow.expenses.divide(closed.length);
    }
    // Si registras el arriendo como ingreso, ya está en el pasivo.
    other = (other - passive).max(Money.zero);

    return CashflowStatement(
      salary: salary,
      otherIncome: other,
      passiveIncome: passive,
      expenses: expenses,
      debtPayments: Money.sum(
        debts
            .where((d) => d.currentBalance.isPositive)
            .map((d) => d.terms?.monthlyPayment ?? Money.zero),
      ),
      cyclesUsed: closed.length,
      incomeAssets: [
        for (final a in assets)
          if (a.monthlyNet.isPositive) _item(a),
      ],
      costlyAssets: [
        for (final a in assets)
          if (a.monthlyNet.isNegative) _item(a),
      ],
      savings: Money.sum(
        assets
            .where(
              (a) =>
                  a.monthlyNet.isZero &&
                  (a.type == AssetType.cash || a.type == AssetType.bankAccount),
            )
            .map((a) => a.currentValue),
      ),
      investments: [
        for (final i in investments)
          CashflowItem(
            name: i.name,
            value: i.currentValue,
            monthly: Money.zero,
          ),
      ],
      liabilities: [
        for (final d in debts)
          if (d.currentBalance.isPositive)
            CashflowItem(
              name: d.name,
              value: d.currentBalance,
              monthly: -(d.terms?.monthlyPayment ?? Money.zero),
            ),
      ],
    );
  }

  static CashflowItem _item(Asset a) =>
      CashflowItem(name: a.name, value: a.currentValue, monthly: a.monthlyNet);

  static Money _salary(Iterable<Transaction> transactions) => Money.sum(
    transactions
        .where((t) => t.isIncome && t.categoryId == DefaultCategories.salaryId)
        .map((t) => t.amount),
  );

  static Money _income(Iterable<Transaction> transactions) => Money.sum(
    transactions
        .where(
          (t) =>
              t.isIncome &&
              t.categoryId != DefaultCategories.balanceAdjustment.id,
        )
        .map((t) => t.amount),
  );
}
