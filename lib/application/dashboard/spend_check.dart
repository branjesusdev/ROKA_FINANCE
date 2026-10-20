import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/salary_forecast.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';

/// Respuesta corta a "¿puedo gastar esto hoy?".
enum SpendVerdict {
  /// Cabe en lo que te queda del tope de hoy.
  fitsToday,

  /// Cabe en lo libre del ciclo, gastando menos los días que siguen.
  fitsWithRecovery,

  /// Solo si tocas lo apartado (ahorro, pagos del año, presupuesto del mes).
  usesReserves,

  /// No alcanza: tocaría la plata de los fijos.
  notEnough,
}

/// Por qué la respuesta es NO.
enum SpendNoReason {
  /// Tocaría la plata de los fijos de este ciclo.
  touchesFixed,

  /// Tocaría lo apartado (ahorro, pagos del año, presupuesto del mes).
  touchesReserves,

  /// Los días que siguen quedarían con menos de la mitad del tope.
  tooTight,

  /// Este ciclo alcanza, pero un ciclo siguiente cerraría en rojo.
  shortLater,
}

/// La regla definitiva: SÍ o NO, y por qué.
final class SpendDecision {
  const new yes({this.isBig = false})
    : canSpend = true,
      reason = null,
      shortMonth = null,
      when = const ForecastWhen.now();

  const new no({
    required SpendNoReason this.reason,
    required this.when,
    this.shortMonth,
  }) : canSpend = false,
       isBig = false;

  final bool canSpend;

  /// `null` si [canSpend].
  final SpendNoReason? reason;

  /// Primer ciclo que cerraría en rojo con el gasto (si se proyectó).
  final ForecastMonth? shortMonth;

  /// Cuándo sí se puede sin quedar en rojo.
  final ForecastWhen when;

  /// Compra grande frente al sueldo: conviene la regla de las 24 horas.
  final bool isBig;
}

/// Cómo quedan los días que siguen si gastas [spentNow] hoy.
final class SpendPath {
  const new({
    required this.spentNow,
    required this.dailyCapAfter,
    this.dailyCut = Money.zero,
  });

  /// Lo que pagarías hoy.
  final Money spentNow;

  /// Tope diario de los días que siguen hasta el sueldo (`null` si hoy es el
  /// último día del ciclo).
  final Money? dailyCapAfter;

  /// Cuánto menos al día frente al tope de hoy (cero si no baja).
  final Money dailyCut;
}

/// "¿Puedo gastar X hoy?" con el dinero del ciclo: veredicto y caminos
/// para recuperarte (pagar todo hoy, la mitad ahora o esperar al sueldo).
/// Es una simulación: no registra nada.
final class SpendCheck {
  const new({
    required this.amount,
    required this.verdict,
    required this.capToday,
    required this.remainingToday,
    required this.freeLeft,
    required this.daysAfterToday,
    required this.payAll,
    required this.payHalf,
    required this.fromReserves,
    required this.shortfall,
    required this.nextPayday,
    required this.decision,
    this.billsBeforePayday = const [],
    this.forecast,
    this.forecastAfter,
  });

  final Money amount;

  /// SÍ o NO, sin rodeos.
  final SpendDecision decision;

  /// Gastos fijos que aún faltan antes del sueldo (ya descontados).
  final List<ScheduledFixed> billsBeforePayday;

  /// Próximos meses sin el gasto (`null` si no se proyectó).
  final SalaryForecast? forecast;

  /// Próximos meses si lo pagas hoy.
  final SalaryForecast? forecastAfter;

  Money get billsTotal =>
      Money.sum(billsBeforePayday.map((s) => s.movement.amount));
  final SpendVerdict verdict;

  /// Tope del día a día de hoy, sin el gasto nuevo.
  final Money capToday;

  /// Lo que queda del tope de hoy.
  final Money remainingToday;

  /// Libre para el día a día hasta el sueldo (incluye lo que queda de hoy).
  final Money freeLeft;

  /// Días del ciclo después de hoy.
  final int daysAfterToday;

  final SpendPath payAll;

  /// Pagar la mitad hoy y la otra mitad con el próximo sueldo.
  final SpendPath payHalf;

  /// Lo que saldría de lo apartado (ahorro, pagos del año, presupuesto).
  final Money fromReserves;

  /// Lo que faltaría incluso tocando lo apartado (sale de los fijos).
  final Money shortfall;

  /// Día del próximo sueldo (esperar no afecta este ciclo).
  final DateTime nextPayday;

  /// El tope de los días que siguen baja a menos de [tightShare] del de hoy.
  bool get isTight => SpendCheckBuilder._isTight(payAll, capToday);

  /// Desde aquí recuperarse se siente: menos de la mitad del tope.
  static const tightShare = Percentage.whole(50);
}

final class SpendCheckBuilder {
  const new();

  /// Desde esta parte del sueldo una compra es "grande".
  static const bigShare = Percentage.whole(20);

  /// `null` si el ciclo ya terminó (no hay tope) o el monto no es positivo.
  /// Con [forecast], el SÍ exige además que ningún ciclo siguiente cierre
  /// en rojo.
  SpendCheck? build({
    required CycleSummary summary,
    required Money amount,
    SalaryForecast? forecast,
  }) {
    final cap = summary.dailyCap;
    final daysLeft = summary.daysLeft;
    if (cap == null || daysLeft <= 0 || !amount.isPositive) return null;
    // Igual que el tope: lo del ciclo tras fijos, menos lo apartado.
    final reserved = cap.reserved;
    final freeLeft = (summary.leftAfterFixed - reserved).max(Money.zero);
    final remainingToday = cap.remainingToday.max(Money.zero);
    final daysAfter = daysLeft - 1;

    SpendPath path(Money spentNow) {
      if (daysAfter == 0) {
        return SpendPath(spentNow: spentNow, dailyCapAfter: null);
      }
      final after = (freeLeft - spentNow).max(Money.zero).divide(daysAfter);
      return SpendPath(
        spentNow: spentNow,
        dailyCapAfter: after,
        dailyCut: (cap.cap - after).max(Money.zero),
      );
    }

    final afterFree = (amount - freeLeft).max(Money.zero);
    final fromReserves = afterFree.min(reserved);
    final shortfall = (afterFree - reserved).max(Money.zero);
    final verdict = amount <= remainingToday
        ? SpendVerdict.fitsToday
        : !afterFree.isPositive
        ? SpendVerdict.fitsWithRecovery
        : !shortfall.isPositive
        ? SpendVerdict.usesReserves
        : SpendVerdict.notEnough;

    final payAll = path(amount);
    final after = forecast?.withSpend(amount);
    final shortMonth = after?.firstShort;
    final tight = _isTight(payAll, cap.cap);
    final when = forecast?.whenAffordable(amount) ?? const ForecastWhen.never();
    final reason = switch (verdict) {
      SpendVerdict.notEnough => SpendNoReason.touchesFixed,
      SpendVerdict.usesReserves => SpendNoReason.touchesReserves,
      SpendVerdict.fitsWithRecovery when tight => SpendNoReason.tooTight,
      // Lo del tope de hoy ya está en el ritmo de gasto proyectado.
      SpendVerdict.fitsWithRecovery
          when after != null && !after.staysPositive =>
        SpendNoReason.shortLater,
      _ => null,
    };
    final salary = forecast?.salary ?? summary.income;
    final decision = reason == null
        ? SpendDecision.yes(
            isBig:
                salary.isPositive && amount >= salary.applyPercentage(bigShare),
          )
        : SpendDecision.no(reason: reason, when: when, shortMonth: shortMonth);

    return SpendCheck(
      amount: amount,
      verdict: verdict,
      decision: decision,
      billsBeforePayday: [
        ...summary.upcomingFixed.awaitingAmount,
        ...summary.upcomingFixed.upcoming,
      ].where((s) => s.movement.isExpense).toList(),
      forecast: forecast,
      forecastAfter: after,
      capToday: cap.cap,
      remainingToday: remainingToday,
      freeLeft: freeLeft,
      daysAfterToday: daysAfter,
      payAll: payAll,
      payHalf: path(amount.divide(2)),
      fromReserves: fromReserves,
      shortfall: shortfall,
      nextPayday: summary.cycle.endExclusive,
    );
  }

  static bool _isTight(SpendPath path, Money capToday) {
    final after = path.dailyCapAfter;
    if (after == null || !capToday.isPositive) return false;
    final share = Percentage.ratio(after, capToday);
    return share != null && share < SpendCheck.tightShare;
  }
}
