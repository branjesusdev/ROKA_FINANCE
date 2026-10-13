import 'package:finance_app/application/common/money_text.dart';
import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/application/dashboard/money_overview.dart';
import 'package:finance_app/domain/budgets/budget_evaluator.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/fixed/fixed_coverage.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/asset.dart';

/// Qué tan importante es una alerta. El orden es el de la urgencia.
enum AlertSeverity { critical, warning, info, positive }

/// De qué trata (la UI elige el icono).
enum AlertKind {
  liquidity,
  dailyCap,
  fixedNotCovered,
  provisionBehind,
  overBudget,
  categorySurge,
  expensiveDebt,
  idleMoney,
  assetDrain,
  emergencyFund,
  goalReached,
}

/// Alerta calculada con reglas fijas (no depende de la IA). Siempre propone
/// una acción.
final class FinancialAlert {
  const new({
    required this.key,
    required this.kind,
    required this.severity,
    required this.title,
    required this.detail,
    required this.action,
  });

  /// Identifica la situación (para no repetir avisos).
  final String key;
  final AlertKind kind;
  final AlertSeverity severity;
  final String title;
  final String detail;
  final String action;
}

/// Revisa el ciclo, presupuestos, apartados, deudas, activos y metas, y
/// devuelve solo lo que vale la pena decir, de lo más urgente a lo menos.
final class FinancialAlertsBuilder {
  const new();

  /// Una categoría "se dispara" si va al menos este % por encima del ciclo
  /// pasado a la misma altura…
  static const surgeFrom = Percentage.whole(30);

  /// …y la diferencia es de al menos este monto (evita ruido).
  static const surgeMinDifference = Money.pesos(50000);

  /// Fijos que vencen dentro de estos días cuentan para la alerta.
  static const fixedHorizonDays = 7;

  /// Apartados que vencen dentro de estos días cuentan para la alerta.
  static const provisionHorizonDays = 45;

  /// Máximo de alertas por tipo repetible (presupuestos, alzas).
  static const maxPerKind = 2;

  List<FinancialAlert> build({
    required CycleSummary summary,
    required MoneyOverview overview,
    required List<Category> categories,
    required List<Transaction> cycleTransactions,
    required List<Transaction> previousCycleTransactions,
    required List<Debt> debts,
    required List<Asset> assets,
    required List<GoalProgressItem> goals,
    required FinanceSettings settings,
    MonthBudgetStatus? budget,
  }) {
    final byId = {for (final c in categories) c.id: c};
    String name(String id) => byId[id]?.name ?? 'Una categoría';
    final alerts = <FinancialAlert>[
      ?_liquidity(overview, summary),
      ?_dailyCap(summary),
      ..._fixed(overview, summary.today),
      ..._provisions(summary),
      ..._budget(budget, name),
      ..._surges(
        summary,
        cycleTransactions,
        previousCycleTransactions,
        categories,
        name,
      ),
      ..._debts(debts),
      ?_idle(summary, goals),
      ..._assets(assets),
      ?_emergency(goals),
      ..._goalsReached(goals),
    ];
    return alerts..sort((a, b) => a.severity.index.compareTo(b.severity.index));
  }

  FinancialAlert? _liquidity(MoneyOverview overview, CycleSummary summary) {
    final shortfall = overview.shortfall;
    if (shortfall == null || overview.lacksData) return null;
    final fixedGap = overview.coverage.missing;
    return FinancialAlert(
      key: 'liquidity-${summary.cycle.start.toIso8601String()}',
      kind: AlertKind.liquidity,
      severity: fixedGap.isPositive
          ? AlertSeverity.critical
          : AlertSeverity.warning,
      title: fixedGap.isPositive
          ? 'Te faltan ${_m(fixedGap)} para tus pagos fijos'
          : 'Lo reservado supera tu dinero por ${_m(shortfall)}',
      detail:
          'Tienes ${_m(overview.available)} y debes reservar '
          '${_m(overview.reserved)} (fijos, apartados y ahorro) en los '
          '${overview.daysLeft} días que quedan del ciclo.',
      action: fixedGap.isPositive
          ? 'Pausa lo que no sea esencial y prioriza arriendo, servicios y '
                'comida hasta el sueldo.'
          : 'Baja el ahorro de este ciclo o recorta un gasto variable.',
    );
  }

  FinancialAlert? _dailyCap(CycleSummary summary) {
    final cap = summary.dailyCap;
    if (cap == null || !cap.exceeded) return null;
    final today = summary.today;
    return FinancialAlert(
      key: 'cap-${today.year}-${today.month}-${today.day}',
      kind: AlertKind.dailyCap,
      severity: AlertSeverity.warning,
      title: 'Hoy pasaste tu tope por ${_m(cap.remainingToday.abs)}',
      detail: 'Tu tope de hoy era ${_m(cap.cap)}.',
      action: 'Pausa compras no planeadas hasta mañana.',
    );
  }

  Iterable<FinancialAlert> _fixed(
    MoneyOverview overview,
    DateTime today,
  ) sync* {
    final day = DateTime(today.year, today.month, today.day);
    final horizon = day.add(const Duration(days: fixedHorizonDays));
    for (final item in overview.coverage.pending) {
      final overdue = item.state == ObligationState.overdue;
      final short =
          item.state == ObligationState.partial ||
          item.state == ObligationState.uncovered;
      if (!overdue && !(short && !item.date.isAfter(horizon))) continue;
      final days = item.date.difference(day).inDays;
      yield FinancialAlert(
        key: 'fixed-${item.movement.id}-${item.date.toIso8601String()}',
        kind: AlertKind.fixedNotCovered,
        severity: overdue ? AlertSeverity.warning : AlertSeverity.critical,
        title: overdue
            ? '${item.movement.name}: falta el valor real'
            : '${item.movement.name} vence '
                  '${days <= 0 ? 'hoy' : 'en $days días'} y faltan '
                  '${_m(item.missing)}',
        detail: overdue
            ? 'Su día ya pasó. Mientras no lo confirmes se reserva el '
                  'estimado de ${_m(item.amount)}.'
            : 'Cuesta ${_m(item.amount)} y con lo que tienes alcanzas a '
                  'cubrir ${_m(item.reserved)}.',
        action: overdue
            ? 'Escribe el valor de la factura en Inicio.'
            : 'Separa ${_m(item.missing)} antes del ${item.date.day} o '
                  'recorta gastos variables.',
      );
    }
  }

  Iterable<FinancialAlert> _provisions(CycleSummary summary) sync* {
    for (final status in summary.provisionPlan.statuses) {
      final behind = status.behind;
      final soon = status.daysUntilDue <= provisionHorizonDays;
      if (!status.isOverdue && !(soon && behind.isPositive)) continue;
      yield FinancialAlert(
        key: 'provision-${status.provision.id}',
        kind: AlertKind.provisionBehind,
        severity: AlertSeverity.warning,
        title: status.isOverdue
            ? '${status.provision.name} ya venció'
            : '${status.provision.name}: vas atrasado ${_m(behind)}',
        detail: status.isOverdue
            ? 'Márcalo como pagado o cambia su fecha.'
            : 'Vence en ${status.daysUntilDue} días y cuesta '
                  '${_m(status.provision.amount)}. Llevas ${_m(status.saved)}.',
        action: status.isOverdue
            ? 'Abre Pagos del año y actualízalo.'
            : 'Aparta ${_m(status.perCycle)} de cada sueldo hasta su fecha.',
      );
    }
  }

  Iterable<FinancialAlert> _budget(
    MonthBudgetStatus? budget,
    String Function(String) name,
  ) sync* {
    if (budget == null) return;
    final over =
        budget.categories
            .where((c) => c.status.light == TrafficLight.critical)
            .toList()
          ..sort(
            (a, b) => (b.status.spent - b.status.limit).compareTo(
              a.status.spent - a.status.limit,
            ),
          );
    for (final line in over.take(maxPerKind)) {
      final excess = line.status.spent - line.status.limit;
      yield FinancialAlert(
        key:
            'budget-${budget.period.year}-${budget.period.month}-'
            '${line.categoryId}',
        kind: AlertKind.overBudget,
        severity: AlertSeverity.warning,
        title: excess.isPositive
            ? '${name(line.categoryId)}: pasaste el presupuesto por '
                  '${_m(excess)}'
            : '${name(line.categoryId)} está al límite del presupuesto',
        detail:
            'Llevas ${_m(line.status.spent)} de ${_m(line.status.limit)} '
            'este mes.',
        action: 'Evita gastar más en ${name(line.categoryId)} este mes.',
      );
    }
  }

  Iterable<FinancialAlert> _surges(
    CycleSummary summary,
    List<Transaction> current,
    List<Transaction> previous,
    List<Category> categories,
    String Function(String) name,
  ) sync* {
    final previousCycle = summary.previousCycle;
    if (previousCycle == null) return;
    final savingIds = {
      for (final c in categories)
        if (c.countsAsSaving) c.id,
    };
    // Misma altura del ciclo pasado.
    final elapsed = summary.today.difference(summary.cycle.start);
    final cutoff = previousCycle.start.add(elapsed);
    Map<String, Money> totals(Iterable<Transaction> list) {
      final result = <String, Money>{};
      for (final t in list) {
        if (!CycleSummaryBuilder.isDayToDay(t, savingIds)) continue;
        result.update(
          t.categoryId,
          (a) => a + t.amount,
          ifAbsent: () => t.amount,
        );
      }
      return result;
    }

    final now = totals(current);
    final before = totals(previous.where((t) => t.date.isBefore(cutoff)));
    final rising = [
      for (final MapEntry(key: id, value: amount) in now.entries)
        if (before[id] case final prior?
            when prior.isPositive &&
                amount - prior >= surgeMinDifference &&
                Percentage.ratio(amount - prior, prior)! >= surgeFrom)
          (id, amount, prior),
    ]..sort((a, b) => (b.$2 - b.$3).compareTo(a.$2 - a.$3));
    for (final (id, amount, prior) in rising.take(maxPerKind)) {
      final change = Percentage.ratio(amount - prior, prior)!;
      yield FinancialAlert(
        key: 'surge-${summary.cycle.start.toIso8601String()}-$id',
        kind: AlertKind.categorySurge,
        severity: AlertSeverity.warning,
        title:
            '${name(id)} subió ${change.value.round()}% frente al ciclo '
            'pasado',
        detail:
            'Llevas ${_m(amount)}; a esta altura del ciclo pasado ibas en '
            '${_m(prior)}.',
        action: 'Revisa los gastos de ${name(id)} y fija un tope.',
      );
    }
  }

  Iterable<FinancialAlert> _debts(List<Debt> debts) sync* {
    for (final debt in debts) {
      final terms = debt.terms;
      if (debt.isPaidOff || terms == null) continue;
      final rate = Percentage.fromFraction(terms.rate.annualEffective);
      if (rate < FinanceSettings.expensiveDebtRate) continue;
      final interest = debt.currentBalance.times(terms.rate.monthlyEffective);
      yield FinancialAlert(
        key: 'debt-${debt.id}',
        kind: AlertKind.expensiveDebt,
        severity: AlertSeverity.info,
        title: '${debt.name} cobra ${rate.value.toStringAsFixed(1)}% al año',
        detail:
            'Son unos ${_m(interest)} de intereses al mes sobre un saldo de '
            '${_m(debt.currentBalance)}.',
        action:
            'Evalúa abonos a capital o comprar la cartera con otra entidad '
            'a menor tasa (simúlalo en el detalle de la deuda).',
      );
    }
  }

  FinancialAlert? _idle(CycleSummary summary, List<GoalProgressItem> goals) {
    final left = summary.previousLeft;
    if (left == null || !left.isPositive) return null;
    final target = goals
        .where((g) => !g.progress.isCompleted)
        .map((g) => g.goal.name)
        .firstOrNull;
    return FinancialAlert(
      key: 'idle-${summary.cycle.start.toIso8601String()}',
      kind: AlertKind.idleMoney,
      severity: AlertSeverity.info,
      title: 'Sobraron ${_m(left)} del ciclo pasado',
      detail: 'Quietos pierden poder de compra con la inflación.',
      action: target == null
          ? 'Crea una meta (fondo de emergencia, por ejemplo) y asígnalos.'
          : 'Asígnalos a "$target" en Metas.',
    );
  }

  Iterable<FinancialAlert> _assets(List<Asset> assets) sync* {
    for (final asset in assets) {
      if (!asset.monthlyNet.isNegative || !asset.monthlyIncome.isPositive) {
        continue;
      }
      yield FinancialAlert(
        key: 'asset-${asset.id}',
        kind: AlertKind.assetDrain,
        severity: AlertSeverity.info,
        title: '${asset.name} cuesta más de lo que produce',
        detail:
            'Produce ${_m(asset.monthlyIncome)} y cuesta '
            '${_m(asset.monthlyCost)} al mes (${_m(asset.monthlyNet.abs)} '
            'menos).',
        action: 'Revisa sus costos o si conviene subir el ingreso o venderlo.',
      );
    }
  }

  FinancialAlert? _emergency(List<GoalProgressItem> goals) {
    final emergency = goals
        .where((g) => g.goal.type == GoalType.emergency)
        .firstOrNull;
    if (emergency != null) return null;
    return const FinancialAlert(
      key: 'emergency-missing',
      kind: AlertKind.emergencyFund,
      severity: AlertSeverity.info,
      title: 'Aún no tienes fondo de emergencia',
      detail: 'Es lo que te protege de endeudarte ante un imprevisto.',
      action: 'Créalo en Metas: la app sugiere el monto con tus gastos.',
    );
  }

  Iterable<FinancialAlert> _goalsReached(List<GoalProgressItem> goals) sync* {
    for (final item in goals.where((g) => g.progress.isCompleted)) {
      yield FinancialAlert(
        key: 'goal-${item.goal.id}',
        kind: AlertKind.goalReached,
        severity: AlertSeverity.positive,
        title: '¡Cumpliste "${item.goal.name}"!',
        detail: 'Ahorraste ${_m(item.progress.saved)}.',
        action: 'Elige la siguiente meta para no frenar el impulso.',
      );
    }
  }

  static String _m(Money money) => MoneyText.format(money);
}
