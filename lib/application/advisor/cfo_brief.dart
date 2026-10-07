import 'dart:math' as math;

import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/application/markets/load_watchlist.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/daily_spending_cap.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/markets/watchlist.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wisdom/wealth_wisdom.dart';

/// Consejo accionable basado en los datos del usuario. La UI lo redacta.
sealed class CoachTip {
  const new();
}

/// Cómo vas hoy frente al tope diario.
final class DailyCapTip extends CoachTip {
  const new(this.cap);

  final DailySpendingCap cap;
}

/// Compras pequeñas del día a día que, sumadas, pesan.
final class SmallLeaksTip extends CoachTip {
  const new({
    required this.count,
    required this.total,
    required this.threshold,
    required this.yearlyPace,
  });

  final int count;
  final Money total;
  final Money threshold;

  /// Lo que sumarían en un año a este ritmo.
  final Money yearlyPace;
}

/// La categoría del día a día donde más se va el dinero.
final class TopCategoryTip extends CoachTip {
  const new({
    required this.category,
    required this.amount,
    required this.share,
  });

  final Category? category;
  final Money amount;
  final Percentage share;
}

/// Dinero que sobró y está quieto: pierde poder de compra.
final class IdleMoneyTip extends CoachTip {
  const new({required this.amount, required this.yearlyLoss});

  final Money amount;
  final Money yearlyLoss;
}

/// Sin fondo de emergencia, o incompleto.
final class EmergencyFundTip extends CoachTip {
  const new({required this.missing, this.progress});

  final Money missing;

  /// `null` si todavía no existe la meta.
  final Percentage? progress;
}

/// Deuda con tasa alta: abonarle rinde más que casi cualquier inversión.
final class ExpensiveDebtTip extends CoachTip {
  const new({
    required this.debt,
    required this.annualRate,
    required this.monthlyInterest,
  });

  final Debt debt;
  final Percentage annualRate;
  final Money monthlyInterest;
}

/// El ahorro del ciclo va por debajo de la referencia.
final class SavingsBehindTip extends CoachTip {
  const new({required this.target, required this.saved});

  final Money target;
  final Money saved;
}

/// No alcanza para los fijos hasta el próximo sueldo.
final class DeficitTip extends CoachTip {
  const new({required this.deficit, required this.daysLeft});

  final Money deficit;
  final int daysLeft;
}

/// El ciclo anterior cerró en negativo o con gastos sin registrar.
final class PreviousCycleTip extends CoachTip {
  const new({required this.result, required this.untracked});

  /// Lo que quedó (negativo = déficit).
  final Money result;

  /// Gastos que no se anotaron y salieron al cuadrar.
  final Money untracked;
}

/// Hijos a cargo: el plan se ajusta (fondo más grande, apartado para
/// imprevistos de los niños).
final class DependentsTip extends CoachTip {
  const new({
    required this.dependents,
    required this.soloProvider,
    required this.emergencyMonths,
    required this.familySpent,
    this.suggestedBuffer,
  });

  final int dependents;
  final bool soloProvider;
  final int emergencyMonths;

  /// Gasto en Hijos/Familia en este ciclo.
  final Money familySpent;

  /// Apartado mensual sugerido si aún no se configuró uno.
  final Money? suggestedBuffer;
}

/// Principio general (cuando no hay nada más urgente que decir).
final class PrincipleTip extends CoachTip {
  const new(this.principle);

  final WealthPrinciple principle;
}

enum PlanSliceKind { emergencyFund, debt, broadFund, thematic }

/// Una parte del reparto sugerido.
final class PlanSlice {
  const new({required this.kind, required this.amount, this.label});

  final PlanSliceKind kind;
  final Money amount;

  /// Nombre de la deuda, del fondo o de la empresa sugerida.
  final String? label;
}

/// Qué hacer con el dinero que sobra (o que conviene apartar) este ciclo,
/// y cuánto cuesta cada opción.
final class CyclePlan {
  const new({
    required this.amount,
    required this.fromPreviousCycle,
    required this.slices,
    required this.idleCostPerYear,
    required this.investedExample,
    this.thematicPick,
  });

  final Money amount;

  /// `true`: es el sobrante del ciclo anterior. `false`: el ahorro de
  /// referencia de este ciclo (págate primero).
  final bool fromPreviousCycle;
  final List<PlanSlice> slices;

  /// Poder de compra que pierde [amount] en un año si se queda quieto.
  final Money idleCostPerYear;

  /// [amount] invertido con la rentabilidad ilustrativa durante los años de
  /// referencia (no garantizado).
  final Money investedExample;

  /// Instrumento temático de la lista que hoy está más lejos de su máximo
  /// con tendencia anual positiva (si hay precios).
  final WatchQuote? thematicPick;
}

final class CfoBrief {
  const new({required this.tips, required this.plan});

  final List<CoachTip> tips;
  final CyclePlan? plan;
}

/// Arma el informe de "Tu CFO": consejos ordenados por urgencia y el plan
/// para el dinero que sobra. Descriptivo, nunca asesoría financiera.
final class CfoBriefBuilder {
  const new();

  static const _daysPerYear = 365;

  CfoBrief build({
    required CycleSummary cycle,
    required List<Transaction> cycleTransactions,
    required List<Category> categories,
    required List<Debt> debts,
    required List<GoalProgressItem> goals,
    required Money essentialMonthly,
    required FinanceSettings settings,
    required DateTime today,
    List<WatchQuote> watchlist = const [],
    List<Transaction> previousTransactions = const [],
    bool previousLeftAlreadySaved = false,
  }) {
    final savingIds = {
      for (final c in categories)
        if (c.countsAsSaving) c.id,
    };
    final byId = {for (final c in categories) c.id: c};
    final emergencyMissing = _emergencyMissing(
      goals,
      essentialMonthly,
      settings.emergencyMonths,
    );
    final expensive = _expensiveDebts(debts);
    final previousLeft = cycle.previousLeft;
    final idle =
        previousLeft != null &&
            previousLeft.isPositive &&
            !previousLeftAlreadySaved
        ? previousLeft
        : null;

    final previousCycleTip = _previousCycle(cycle, previousTransactions);
    final tips = <CoachTip>[
      if (cycle.deficit case final deficit?)
        DeficitTip(deficit: deficit, daysLeft: cycle.daysLeft),
      if (cycle.dailyCap case final cap?) DailyCapTip(cap),
      ?previousCycleTip,
      if (settings.hasDependents)
        DependentsTip(
          dependents: settings.dependents,
          soloProvider: settings.soloProvider,
          emergencyMonths: settings.emergencyMonths,
          familySpent: Money.sum(
            cycleTransactions
                .where(
                  (t) =>
                      t.isExpense &&
                      t.categoryId == CycleSummaryBuilder.familyCategoryId,
                )
                .map((t) => t.amount),
          ),
          suggestedBuffer: settings.kidsMonthlyBuffer.isPositive
              ? null
              : cycle.income
                    .applyPercentage(
                      FinanceSettings.suggestedKidsBufferPerChild,
                    )
                    .times(settings.dependents),
        ),
      for (final (debt, rate) in expensive.take(1))
        ExpensiveDebtTip(
          debt: debt,
          annualRate: rate,
          monthlyInterest: debt.currentBalance.times(
            debt.terms!.rate.monthlyEffective,
          ),
        ),
      if (idle != null)
        IdleMoneyTip(
          amount: idle,
          yearlyLoss: idle.applyPercentage(FinanceSettings.referenceInflation),
        ),
      if (emergencyMissing case (final missing, final progress)
          when missing.isPositive)
        EmergencyFundTip(missing: missing, progress: progress),
      ?_leaks(cycle, cycleTransactions, savingIds, settings, today),
      ?_topCategory(cycleTransactions, savingIds, byId),
      ?_savingsBehind(cycle),
      PrincipleTip(
        WealthWisdom.principles[today.day % WealthWisdom.principles.length],
      ),
    ];

    return CfoBrief(
      tips: tips,
      plan: _plan(
        cycle: cycle,
        settings: settings,
        idle: idle,
        emergencyMissing: emergencyMissing?.$1 ?? Money.zero,
        expensive: expensive,
        watchlist: watchlist,
      ),
    );
  }

  /// (faltante, progreso). Sin meta, sugiere [months] meses de gastos
  /// esenciales (más si hay hijos a cargo).
  (Money, Percentage?)? _emergencyMissing(
    List<GoalProgressItem> goals,
    Money essentialMonthly,
    int months,
  ) {
    final emergency = goals
        .where((g) => g.goal.type == GoalType.emergency)
        .firstOrNull;
    if (emergency != null) {
      return (emergency.progress.remaining, emergency.progress.progress);
    }
    if (!essentialMonthly.isPositive) return null;
    return (essentialMonthly.times(months), null);
  }

  PreviousCycleTip? _previousCycle(
    CycleSummary cycle,
    List<Transaction> previousTransactions,
  ) {
    final result = cycle.previousLeft;
    if (result == null) return null;
    final untracked = Money.sum(
      previousTransactions
          .where(
            (t) =>
                t.isExpense && t.categoryId == DefaultCategories.untracked.id,
          )
          .map((t) => t.amount),
    );
    if (!result.isNegative && !untracked.isPositive) return null;
    return PreviousCycleTip(result: result, untracked: untracked);
  }

  List<(Debt, Percentage)> _expensiveDebts(List<Debt> debts) {
    final result = <(Debt, Percentage)>[
      for (final debt in debts)
        if (!debt.isPaidOff && debt.terms != null)
          (debt, Percentage.fromFraction(debt.terms!.rate.annualEffective)),
    ].where((d) => d.$2 >= FinanceSettings.expensiveDebtRate).toList();
    return result..sort((a, b) => b.$2.compareTo(a.$2));
  }

  SmallLeaksTip? _leaks(
    CycleSummary cycle,
    List<Transaction> transactions,
    Set<String> savingIds,
    FinanceSettings settings,
    DateTime today,
  ) {
    final small = transactions
        .where(
          (t) =>
              CycleSummaryBuilder.isDayToDay(t, savingIds) &&
              t.amount <= settings.smallExpenseThreshold,
        )
        .toList();
    if (small.length < 3) return null;
    final total = Money.sum(small.map((t) => t.amount));
    final elapsed = math.max(
      1,
      cycle.cycle.totalDays - cycle.cycle.daysLeft(today) + 1,
    );
    return SmallLeaksTip(
      count: small.length,
      total: total,
      threshold: settings.smallExpenseThreshold,
      yearlyPace: total.times(_daysPerYear / elapsed),
    );
  }

  TopCategoryTip? _topCategory(
    List<Transaction> transactions,
    Set<String> savingIds,
    Map<String, Category> byId,
  ) {
    final totals = <String, Money>{};
    for (final t in transactions.where(
      (t) => CycleSummaryBuilder.isDayToDay(t, savingIds),
    )) {
      totals.update(
        t.categoryId,
        (a) => a + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    if (totals.isEmpty) return null;
    final top = totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return TopCategoryTip(
      category: byId[top.key],
      amount: top.value,
      share:
          Percentage.ratio(top.value, Money.sum(totals.values)) ??
          Percentage.zero,
    );
  }

  SavingsBehindTip? _savingsBehind(CycleSummary cycle) {
    final saved = cycle.cashFlow.savingContributions;
    final target = cycle.savingsTarget;
    if (!target.isPositive || saved >= target) return null;
    return SavingsBehindTip(target: target, saved: saved);
  }

  CyclePlan? _plan({
    required CycleSummary cycle,
    required FinanceSettings settings,
    required Money? idle,
    required Money emergencyMissing,
    required List<(Debt, Percentage)> expensive,
    required List<WatchQuote> watchlist,
  }) {
    final amount = idle ?? cycle.savingsTarget;
    if (!amount.isPositive) return null;

    var rest = amount;
    final slices = <PlanSlice>[];
    if (emergencyMissing.isPositive) {
      final toEmergency = amount
          .applyPercentage(settings.emergencyShareOfLeftover)
          .min(emergencyMissing);
      slices.add(
        PlanSlice(kind: PlanSliceKind.emergencyFund, amount: toEmergency),
      );
      rest -= toEmergency;
    }
    if (expensive.isNotEmpty && rest.isPositive) {
      final (debt, _) = expensive.first;
      final toDebt = rest
          .applyPercentage(FinanceSettings.expensiveDebtShare)
          .min(debt.currentBalance);
      slices.add(
        PlanSlice(kind: PlanSliceKind.debt, amount: toDebt, label: debt.name),
      );
      rest -= toDebt;
    }
    final pick = _thematicPick(watchlist);
    if (rest.isPositive) {
      final broad = rest.applyPercentage(FinanceSettings.broadFundShare);
      final broadItem = TechWatchlist.items
          .where((i) => i.kind == WatchKind.broadFund)
          .firstOrNull;
      slices
        ..add(
          PlanSlice(
            kind: PlanSliceKind.broadFund,
            amount: broad,
            label: broadItem?.name,
          ),
        )
        ..add(
          PlanSlice(
            kind: PlanSliceKind.thematic,
            amount: rest - broad,
            label: pick?.item.name,
          ),
        );
    }

    final growth = math.pow(
      1 + FinanceSettings.illustrativeAnnualReturn.fraction,
      FinanceSettings.illustrativeYears,
    );
    return CyclePlan(
      amount: amount,
      fromPreviousCycle: idle != null,
      slices: slices,
      idleCostPerYear: amount.applyPercentage(
        FinanceSettings.referenceInflation,
      ),
      investedExample: amount.times(growth),
      thematicPick: pick,
    );
  }

  /// El temático más lejos de su máximo del año que aún sube en el año;
  /// si ninguno sube, el menos volátil.
  WatchQuote? _thematicPick(List<WatchQuote> watchlist) {
    final candidates = watchlist
        .where((w) => w.item.kind != WatchKind.broadFund && w.stats != null)
        .toList();
    final rising = candidates
        .where(
          (w) =>
              (w.stats!.change1y?.basisPoints ?? 0) > 0 &&
              w.stats!.fromHigh != null,
        )
        .toList();
    if (rising.isNotEmpty) {
      return rising.reduce(
        (a, b) => a.stats!.fromHigh! <= b.stats!.fromHigh! ? a : b,
      );
    }
    final withVolatility = candidates
        .where((w) => w.stats!.volatility != null)
        .toList();
    if (withVolatility.isEmpty) return null;
    return withVolatility.reduce(
      (a, b) => a.stats!.volatility! <= b.stats!.volatility! ? a : b,
    );
  }
}
