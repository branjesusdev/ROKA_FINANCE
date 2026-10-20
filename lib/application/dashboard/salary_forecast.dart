import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';

/// De dónde sale el sueldo que usa la proyección.
enum SalarySource {
  /// Lo escribiste en Ajustes.
  configured,

  /// Un ingreso fijo en la categoría Salario.
  fixedIncome,

  /// Promedio de lo que llegó a Salario en los ciclos cerrados.
  history,

  /// Lo que llegó a Salario en este ciclo.
  thisCycle,

  /// No hay cómo saberlo: la proyección solo cuenta gastos.
  unknown,
}

/// Un ciclo de sueldo proyectado.
final class ForecastMonth {
  const new({
    required this.payday,
    required this.income,
    required this.fixedExpenses,
    required this.setAside,
    required this.dayToDay,
    required this.balance,
  });

  /// Día en que llega el sueldo de ese ciclo.
  final DateTime payday;

  /// Sueldo y otros ingresos fijos.
  final Money income;

  /// Gastos fijos (arriendo, cuotas, servicios…).
  final Money fixedExpenses;

  /// Cuota de los pagos del año (SOAT, matrícula…).
  final Money setAside;

  /// Gasto variable esperado (mercado, transporte, antojos…).
  final Money dayToDay;

  /// Lo que llevarías acumulado al cerrar ese ciclo.
  final Money balance;

  /// Lo que sobra (o falta) en ese ciclo.
  Money get net => income - fixedExpenses - setAside - dayToDay;

  bool get isShort => balance.isNegative;

  ForecastMonth _shifted(Money by) => ForecastMonth(
    payday: payday,
    income: income,
    fixedExpenses: fixedExpenses,
    setAside: setAside,
    dayToDay: dayToDay,
    balance: balance - by,
  );
}

/// "¿Estaré corto en los próximos meses?": cómo queda lo libre acumulado
/// al cierre de este ciclo y de los siguientes con tu sueldo, tus fijos,
/// los pagos del año y tu ritmo de gasto. Estimación, no promesa.
final class SalaryForecast {
  const new({
    required this.salary,
    required this.source,
    required this.dayToDayMonthly,
    required this.cycleEnd,
    required this.nextPayday,
    required this.months,
    this.dayToDayFromHistory = true,
  });

  /// Sueldo mensual con el que se proyecta.
  final Money salary;
  final SalarySource source;

  /// Gasto variable de un ciclo.
  final Money dayToDayMonthly;

  /// `false`: sin ciclos cerrados se supone que gastas tu tope y ahorras tu
  /// meta.
  final bool dayToDayFromHistory;

  /// Lo que quedaría al cerrar este ciclo a tu ritmo de gasto.
  final Money cycleEnd;

  /// Llega el próximo sueldo (cierre de este ciclo).
  final DateTime nextPayday;

  /// Ciclos que siguen, del más cercano al más lejano.
  final List<ForecastMonth> months;

  bool get knowsSalary => source != SalarySource.unknown;

  /// Saldo acumulado: cierre de este ciclo y de cada ciclo siguiente.
  List<Money> get balances => [cycleEnd, for (final m in months) m.balance];

  Money get lowest => balances.reduce((a, b) => a.min(b));

  Money get last => balances.last;

  /// Este ciclo cierra en rojo.
  bool get shortThisCycle => cycleEnd.isNegative;

  /// Primer ciclo siguiente que cierra en rojo (`null` si ninguno).
  ForecastMonth? get firstShort {
    for (final m in months) {
      if (m.isShort) return m;
    }
    return null;
  }

  bool get staysPositive => !lowest.isNegative;

  /// La proyección si pagas [amount] hoy.
  SalaryForecast withSpend(Money amount) => SalaryForecast(
    salary: salary,
    source: source,
    dayToDayMonthly: dayToDayMonthly,
    dayToDayFromHistory: dayToDayFromHistory,
    cycleEnd: cycleEnd - amount,
    nextPayday: nextPayday,
    months: [for (final m in months) m._shifted(amount)],
  );

  /// Primer momento en que pagar [amount] no deja ningún ciclo en rojo:
  /// hoy mismo, un día de sueldo o nunca dentro del horizonte.
  ForecastWhen whenAffordable(Money amount) {
    final all = balances;
    for (var from = 0; from < all.length; from++) {
      final worst = all.skip(from).reduce((a, b) => a.min(b));
      if (worst >= amount) {
        return from == 0
            ? const ForecastWhen.now()
            : ForecastWhen.on(months[from - 1].payday);
      }
    }
    return const ForecastWhen.never();
  }
}

/// Cuándo se puede pagar algo sin quedar en rojo.
final class ForecastWhen {
  const new now() : date = null, reachable = true;
  const new on(DateTime this.date) : reachable = true;
  const new never() : date = null, reachable = false;

  /// `null` = hoy (si [reachable]).
  final DateTime? date;

  /// `false`: no alcanza en los meses proyectados.
  final bool reachable;

  bool get isNow => reachable && date == null;
}

final class SalaryForecastBuilder {
  const new();

  /// Ciclos proyectados después del actual.
  static const horizon = 6;

  /// [historySalary]: sueldo promedio de los ciclos cerrados.
  /// [historyDayToDay]: gasto variable promedio de los ciclos cerrados
  /// (`null` sin ciclos cerrados).
  SalaryForecast build({
    required CycleSummary summary,
    required FinanceSettings settings,
    required List<FixedMovement> fixedMovements,
    List<Debt> debts = const [],
    Money historySalary = Money.zero,
    Money? historyDayToDay,
  }) {
    final active = fixedMovements.where((m) => m.isActive).toList();
    bool isSalary(FixedMovement m) =>
        m.categoryId == DefaultCategories.salaryId;
    final fixedSalary = Money.sum(
      active.where((m) => !m.isExpense && isSalary(m)).map((m) => m.amount),
    );
    final thisCycleSalary = Money.sum(
      summary.incomeTotals
          .where((t) => t.categoryId == DefaultCategories.salaryId)
          .map((t) => t.amount),
    );
    final (salary, source) = settings.hasSalary
        ? (settings.monthlySalary, SalarySource.configured)
        : fixedSalary.isPositive
        ? (fixedSalary, SalarySource.fixedIncome)
        : historySalary.isPositive
        ? (historySalary, SalarySource.history)
        : thisCycleSalary.isPositive
        ? (thisCycleSalary, SalarySource.thisCycle)
        : (Money.zero, SalarySource.unknown);
    final otherIncome = Money.sum(
      active.where((m) => !m.isExpense && !isSalary(m)).map((m) => m.amount),
    );

    final pendingNow = {
      for (final s in summary.upcomingFixed.upcoming) s.movement.id,
    };
    final debtById = {for (final d in debts) d.id: d};

    /// Cuotas de un crédito enlazado que quedan después de este ciclo
    /// (`null` = sin fin conocido).
    int? installmentsAfterNow(FixedMovement m) {
      final debt = debtById[m.debtId];
      if (debt == null) return null;
      if (!debt.currentBalance.isPositive) return 0;
      final left = debt.terms?.recordedRemainingInstallments;
      if (left == null) return null;
      return (left - (pendingNow.contains(m.id) ? 1 : 0)).clamp(0, left);
    }

    Money fixedIn(int index) => Money.sum(
      active
          .where((m) => m.isExpense)
          .where((m) {
            final left = installmentsAfterNow(m);
            return left == null || index < left;
          })
          .map((m) => m.amount),
    );

    final setAside = summary.provisionPlan.monthlyEquivalent;
    final fromHistory = historyDayToDay != null;
    // Sin historial: gastas tu tope y ahorras tu meta.
    final dayToDay =
        historyDayToDay ??
        (salary +
                otherIncome -
                fixedIn(0) -
                setAside -
                salary.applyPercentage(settings.savingsTargetRate))
            .max(Money.zero);

    final cycle = summary.cycle;
    final daysLeft = summary.daysLeft;
    final restOfCycle = cycle.totalDays == 0
        ? Money.zero
        : dayToDay.times(daysLeft / cycle.totalDays);
    final cycleEnd =
        summary.leftAfterFixed -
        summary.provisionPlan.pendingThisCycle -
        restOfCycle;

    final next = cycle.endExclusive;
    final months = <ForecastMonth>[];
    var balance = cycleEnd;
    for (var i = 0; i < horizon; i++) {
      final payday = i == 0
          ? next
          : PayCycle.paydayIn(next.year, next.month + i, settings.payday);
      final income = salary + otherIncome;
      final fixed = fixedIn(i);
      balance = balance + income - fixed - setAside - dayToDay;
      months.add(
        ForecastMonth(
          payday: payday,
          income: income,
          fixedExpenses: fixed,
          setAside: setAside,
          dayToDay: dayToDay,
          balance: balance,
        ),
      );
    }
    return SalaryForecast(
      salary: salary,
      source: source,
      dayToDayMonthly: dayToDay,
      dayToDayFromHistory: fromHistory,
      cycleEnd: cycleEnd,
      nextPayday: next,
      months: months,
    );
  }
}
