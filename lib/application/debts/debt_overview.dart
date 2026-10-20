import 'dart:math' as math;

import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/loan_projector.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';

/// Resumen de un crédito: proyección actual y, opcionalmente, la simulación
/// de un abono mensual adicional (sin modificar el crédito real).
/// Lo que dice tu registro (cuotas totales − pagadas), para compararlo con
/// la proyección por saldo y tasa.
final class RecordedSchedule {
  const new({
    required this.months,
    required this.totalToPay,
    required this.fees,
    required this.interest,
    this.impliedAnnualRate,
  });

  /// Cuotas que faltan según tu registro (o el extracto).
  final int months;

  /// Cuota × cuotas que faltan.
  final Money totalToPay;

  /// Seguros y comisiones en esas cuotas.
  final Money fees;

  /// Lo que pagarías de más sobre el saldo, sin seguros (intereses).
  final Money interest;

  /// Tasa efectiva anual (fracción) que haría cuadrar saldo, cuota y
  /// cuotas. `null` si no se puede calcular.
  final double? impliedAnnualRate;
}

/// Lo que te cuesta el crédito completo en intereses: lo ya pagado
/// (aproximado con el plan del crédito) + lo que falta según tu saldo.
final class LoanInterestCost {
  const new({
    required this.paidSoFar,
    required this.remaining,
    required this.plan,
  });

  /// Intereses de las cuotas ya pagadas según el plan desde el valor
  /// inicial. Aproximado: si abonaste de más, pagaste algo menos.
  final Money paidSoFar;

  /// Intereses de las cuotas que faltan (proyección por saldo).
  final Money remaining;

  /// Intereses del crédito completo pagando solo la cuota, sin abonos.
  final Money plan;

  /// Total de intereses del crédito: ya pagados + los que faltan.
  Money get total => paidSoFar + remaining;

  /// Lo que te ahorras frente al plan gracias a abonos o pagos de más.
  Money get savedVsPlan => (plan - total).max(Money.zero);
}

final class DebtOverview {
  const new _({
    required this.debt,
    required this.projection,
    required this.simulation,
    this.recorded,
    this.schedule = const [],
    this.interestCost,
  });

  factory build({
    required Debt debt,
    required YearMonth currentMonth,
    Money extraMonthly = Money.zero,
  }) {
    final terms = debt.terms;
    if (terms == null) {
      return DebtOverview._(debt: debt, projection: null, simulation: null);
    }
    const projector = LoanProjector();
    final paid = terms.paidInstallments;
    final start = terms.startDate;
    // Con fecha de inicio y cuotas pagadas, la próxima cuota es la
    // siguiente del plan (la 1.ª llega un mes después del desembolso).
    final firstPaymentMonth = start != null && paid != null
        ? YearMonth.fromDate(start).addMonths(paid + 1)
        : currentMonth.next;
    final remaining = terms.recordedRemainingInstallments;
    RecordedSchedule? recorded;
    if (remaining != null && remaining > 0) {
      final total = terms.monthlyPayment.times(remaining);
      final fees = terms.monthlyFees.times(remaining);
      final monthly = projector.impliedMonthlyRate(
        balance: debt.currentBalance,
        payment: terms.paymentWithoutFees,
        months: remaining,
      );
      recorded = RecordedSchedule(
        months: remaining,
        totalToPay: total,
        fees: fees,
        interest: (total - fees - debt.currentBalance).max(Money.zero),
        impliedAnnualRate: monthly == null
            ? null
            : math.pow(1 + monthly, YearMonth.monthsPerYear) - 1,
      );
    }
    final schedule = projector.schedule(
      balance: debt.currentBalance,
      terms: terms,
      firstPaymentMonth: firstPaymentMonth,
      firstNumber: paid == null ? null : paid + 1,
    );
    return DebtOverview._(
      recorded: recorded,
      debt: debt,
      schedule: schedule ?? const [],
      interestCost: schedule == null
          ? null
          : _interestCost(debt: debt, remaining: schedule),
      projection: projector.project(
        balance: debt.currentBalance,
        terms: terms,
        firstPaymentMonth: firstPaymentMonth,
      ),
      simulation: extraMonthly.isPositive
          ? projector.compareExtraPayment(
              balance: debt.currentBalance,
              terms: terms,
              firstPaymentMonth: firstPaymentMonth,
              extraMonthly: extraMonthly,
            )
          : null,
    );
  }

  /// Plan desde el valor inicial: sus primeras cuotas aproximan los
  /// intereses ya pagados. `null` sin cuotas pagadas o si no es pagable.
  static LoanInterestCost? _interestCost({
    required Debt debt,
    required List<LoanInstallment> remaining,
  }) {
    final terms = debt.terms!;
    final paid = terms.paidInstallments;
    if (paid == null || !debt.originalAmount.isPositive) return null;
    final plan = const LoanProjector().schedule(
      balance: debt.originalAmount,
      terms: terms,
      // El mes no importa: solo se suman intereses.
      firstPaymentMonth: const YearMonth(2000, 1),
    );
    if (plan == null) return null;
    return LoanInterestCost(
      paidSoFar: Money.sum(plan.take(paid).map((r) => r.interest)),
      remaining: Money.sum(remaining.map((r) => r.interest)),
      plan: Money.sum(plan.map((r) => r.interest)),
    );
  }

  final Debt debt;

  /// Tabla de pagos de las cuotas que faltan (vacía si no hay condiciones
  /// o la cuota no alcanza).
  final List<LoanInstallment> schedule;

  /// Intereses del crédito completo. `null` sin cuotas pagadas anotadas.
  final LoanInterestCost? interestCost;

  /// `null` si la deuda no tiene condiciones de crédito.
  final LoanProjection? projection;
  final LoanComparison? simulation;

  /// Según tu registro de cuotas (`null` si no anotaste total y pagadas).
  final RecordedSchedule? recorded;

  /// Total que pagarías según la proyección: saldo + intereses + seguros.
  Money? get projectedTotal {
    final p = projection;
    if (p == null || !p.isPayable) return null;
    return debt.currentBalance + p.totalInterest + p.totalFees;
  }

  /// La proyección y tu registro no coinciden en cuotas.
  bool get scheduleMismatch {
    final p = projection;
    final r = recorded;
    return p != null && r != null && p.isPayable && p.months != r.months;
  }

  /// Cuotas que vas adelantado frente a tu registro (abonos o pagos de
  /// más). 0 si no vas adelantado o no se puede comparar.
  int get installmentsAhead {
    final p = projection;
    final r = recorded;
    if (p == null || r == null || !p.isPayable) return 0;
    return math.max(0, r.months - p.months);
  }

  bool get hasTerms => debt.terms != null;
}
