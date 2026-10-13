import 'dart:convert';

import 'package:finance_app/application/advisor/financial_alerts.dart';
import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/application/dashboard/money_overview.dart';
import 'package:finance_app/application/markets/load_watchlist.dart';
import 'package:finance_app/domain/budgets/budget_evaluator.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/domain/wealth/net_worth_calculator.dart';
import 'package:finance_app/domain/wealth/net_worth_snapshot.dart';

/// Resumen agregado de las finanzas que se envía a la IA. Es lo único que
/// sale del teléfono y el usuario puede verlo completo antes de activar.
///
/// Privacidad: solo totales, tipos, tasas y nombres de categoría. Nunca
/// descripciones, notas, movimientos uno por uno ni los nombres que el
/// usuario escribió (deudas, bienes, metas y fijos van como "Deuda 1
/// (tarjeta)").
final class FinancialSnapshot {
  const new(this.data);

  final Map<String, Object?> data;

  String toJson() => const JsonEncoder.withIndent(' ').convert(data);
}

final class FinancialSnapshotBuilder {
  const new();

  FinancialSnapshot build({
    required CycleSummary summary,
    required MoneyOverview overview,
    required List<FinancialAlert> alerts,
    required List<Category> categories,
    required List<Transaction> cycleTransactions,
    required List<Transaction> previousCycleTransactions,
    required List<Debt> debts,
    required List<Asset> assets,
    required List<Investment> investments,
    required List<GoalProgressItem> goals,
    required NetWorth netWorth,
    required FinanceSettings settings,
    List<NetWorthSnapshot> netWorthHistory = const [],
    List<WatchQuote> watchlist = const [],
    MonthBudgetStatus? budget,
  }) {
    final byId = {for (final c in categories) c.id: c};
    final savingIds = {
      for (final c in categories)
        if (c.countsAsSaving) c.id,
    };
    String cat(String id) => byId[id]?.name ?? 'Otra';
    final debtLabels = {
      for (final (i, d) in debts.indexed)
        d.id: 'Deuda ${i + 1} (${d.type.name})',
    };
    final income = cycleTransactions.where((t) => t.isIncome);
    bool extraordinary(Transaction t) =>
        byId[t.categoryId]?.isExtraordinary ?? false;

    return FinancialSnapshot({
      'moneda': 'COP (pesos colombianos, valores en pesos enteros)',
      'fecha': _date(summary.today),
      'hogar': {
        'personasACargo': settings.dependents,
        'unicoIngresoDelHogar': settings.soloProvider,
        'mesesSugeridosFondoEmergencia': settings.emergencyMonths,
      },
      'cicloDeSueldo': {
        'inicio': _date(summary.cycle.start),
        'fin': _date(
          summary.cycle.endExclusive.subtract(const Duration(days: 1)),
        ),
        'diasRestantes': summary.daysLeft,
        'diaDePagoHabitual': settings.payday,
        'ingresosRecurrentes': _p(
          Money.sum(
            income.where((t) => !extraordinary(t)).map((t) => t.amount),
          ),
        ),
        'ingresosExtraordinarios': {
          for (final t in income.where(extraordinary))
            cat(t.categoryId): _p(t.amount),
        },
        'gastos': _p(summary.cashFlow.expenses),
        'aportesAhorroEInversion': _p(summary.cashFlow.savingContributions),
        'ahorroDeReferencia': _p(summary.savingsTarget),
        'resultadoCicloAnterior': _pn(summary.previousLeft),
      },
      'dineroHoy': {
        'disponible': _p(overview.available),
        'comprometidoEnFijos': _p(overview.committed),
        'apartadosPendientes': _p(overview.provisionsPending),
        'ahorroPendiente': _p(overview.savingsPending),
        'ingresosFijosPorLlegar': _p(overview.expectedIncome),
        'libreParaGastar': _p(overview.free),
        'topeDiarioCalculado': _pn(summary.dailyCap?.cap),
      },
      'gastoPorCategoriaEsteCiclo': _byCategory(
        cycleTransactions.where((t) => t.isExpense),
        cat,
      ),
      'gastoPorCategoriaCicloAnterior': _byCategory(
        previousCycleTransactions.where((t) => t.isExpense),
        cat,
      ),
      'gastoDiaADiaEsteCiclo': _p(
        Money.sum(
          cycleTransactions
              .where((t) => CycleSummaryBuilder.isDayToDay(t, savingIds))
              .map((t) => t.amount),
        ),
      ),
      'pagosFijos': [
        for (final item in overview.coverage.items)
          {
            'categoria': cat(item.movement.categoryId),
            'valor': _p(item.amount),
            'fecha': _date(item.date),
            'estado': item.state.name,
            'cubierto': _p(item.reserved),
            'variable': item.movement.isVariable,
          },
      ],
      'pagosDelAno': [
        for (final s in summary.provisionPlan.statuses)
          {
            'categoria': cat(s.provision.categoryId),
            'valor': _p(s.provision.amount),
            'cadaMeses': s.provision.everyMonths,
            'diasParaVencer': s.daysUntilDue,
            'apartado': _p(s.saved),
            'cuotaPorCiclo': _p(s.perCycle),
          },
      ],
      if (budget != null)
        'presupuestosDelMes': [
          for (final line in budget.categories)
            {
              'categoria': cat(line.categoryId),
              'limite': _p(line.status.limit),
              'gastado': _p(line.status.spent),
            },
        ],
      'deudas': [
        for (final d in debts.where((d) => !d.isPaidOff))
          {
            'nombre': debtLabels[d.id],
            'saldo': _p(d.currentBalance),
            'montoOriginal': _p(d.originalAmount),
            if (d.terms case final terms?) ...{
              'tasaEfectivaAnual': _pct(
                Percentage.fromFraction(terms.rate.annualEffective),
              ),
              'cuotaMensual': _p(terms.monthlyPayment),
              'cuotasRestantes': terms.recordedRemainingInstallments,
            },
          },
      ],
      'bienes': [
        for (final (i, a) in assets.indexed)
          {
            'nombre': 'Bien ${i + 1}',
            'tipo': a.type.name,
            'valorEstimado': _p(a.currentValue),
            'fechaValoracion': _date(a.valuedAt),
            'costoMensual': _p(a.monthlyCost),
            'ingresoMensual': _p(a.monthlyIncome),
            'liquidez': a.effectiveLiquidity.name,
            if (a.linkedDebtId case final id?) 'financiadoCon': debtLabels[id],
          },
      ],
      'inversiones': [
        for (final inv in investments)
          {
            'tipo': inv.type.name,
            'invertido': _p(inv.investedAmount),
            'valorActual': _p(inv.currentValue),
          },
      ],
      'metas': [
        for (final g in goals)
          {
            'tipo': g.goal.type.name,
            'objetivo': _p(g.progress.target),
            'ahorrado': _p(g.progress.saved),
            'mesesRestantes': ?g.progress.monthsLeft,
            if (g.progress.suggestedMonthly case final m?)
              'aporteMensualNecesario': _p(m),
          },
      ],
      'patrimonio': {
        'activos': _p(netWorth.assets),
        'inversiones': _p(netWorth.investments),
        'pasivos': _p(netWorth.liabilities),
        'neto': _p(netWorth.total),
        'historialMensual': [
          for (final s in netWorthHistory)
            {'mes': '${s.month.year}-${s.month.month}', 'neto': _p(s.total)},
        ],
      },
      if (watchlist.any((w) => w.stats != null))
        'accionesQueSigue': [
          for (final w in watchlist)
            if (w.stats case final stats?)
              {
                'simbolo': w.item.symbol,
                'tipo': w.item.kind.name,
                'cambio12Meses': _pctn(stats.change1y),
                'cambio3Meses': _pctn(stats.change3m),
                'distanciaAlMaximoDelAno': _pctn(stats.fromHigh),
                'volatilidadAnual': _pctn(stats.volatility),
              },
        ],
      'alertasCalculadasPorReglas': [
        for (final a in alerts)
          {'gravedad': a.severity.name, 'alerta': a.title, 'detalle': a.detail},
      ],
    });
  }

  static Map<String, int> _byCategory(
    Iterable<Transaction> list,
    String Function(String) name,
  ) {
    final totals = <String, Money>{};
    for (final t in list) {
      final key = name(t.categoryId);
      totals.update(key, (a) => a + t.amount, ifAbsent: () => t.amount);
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: _p(e.value)};
  }

  static int _p(Money money) => (money.cents / Money.centsPerPeso).round();

  static int? _pn(Money? money) => money == null ? null : _p(money);

  static String _pct(Percentage p) => '${p.value.toStringAsFixed(1)}%';

  static String? _pctn(Percentage? p) => p == null ? null : _pct(p);

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
