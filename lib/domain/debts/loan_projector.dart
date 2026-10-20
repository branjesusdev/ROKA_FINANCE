import 'dart:math' as math;

import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:meta/meta.dart';

final class LoanProjection {
  const new _({
    required this.isPayable,
    required this.months,
    required this.totalInterest,
    required this.totalFees,
    required this.payoffMonth,
  });

  const new payable({
    required int months,
    required Money totalInterest,
    required Money totalFees,
    required YearMonth payoffMonth,
  }) : this._(
         isPayable: true,
         months: months,
         totalInterest: totalInterest,
         totalFees: totalFees,
         payoffMonth: payoffMonth,
       );

  /// La cuota no alcanza a cubrir los intereses: la deuda no termina.
  const new unpayable()
    : this._(
        isPayable: false,
        months: 0,
        totalInterest: Money.zero,
        totalFees: Money.zero,
        payoffMonth: null,
      );

  final bool isPayable;

  /// Cuotas restantes.
  final int months;
  final Money totalInterest;
  final Money totalFees;

  /// Mes de la última cuota. `null` si no es pagable.
  final YearMonth? payoffMonth;
}

/// Una fila de la tabla de pagos: lo que abona a capital y a intereses.
@immutable
final class LoanInstallment {
  const new({
    required this.month,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
    this.number,
  });

  /// Número de la cuota en el crédito (`null` si no se sabe cuántas van).
  final int? number;
  final YearMonth month;

  /// Capital + intereses, sin seguros (la última suele ser menor).
  final Money payment;
  final Money principal;
  final Money interest;

  /// Saldo de capital después de esta cuota.
  final Money balance;
}

final class LoanComparison {
  const new({required this.base, required this.withExtra});

  final LoanProjection base;
  final LoanProjection withExtra;

  /// `null` si alguno de los escenarios no es pagable.
  int? get monthsSaved => base.isPayable && withExtra.isPayable
      ? base.months - withExtra.months
      : null;

  Money? get interestSaved => base.isPayable && withExtra.isPayable
      ? base.totalInterest - withExtra.totalInterest
      : null;
}

/// Proyección de créditos con cuota fija desde el saldo actual.
final class LoanProjector {
  const new({this.maxMonths = defaultMaxMonths});

  /// Límite de seguridad: 100 años.
  static const defaultMaxMonths = 1200;

  final int maxMonths;

  /// [firstPaymentMonth] es el mes de la próxima cuota.
  LoanProjection project({
    required Money balance,
    required LoanTerms terms,
    required YearMonth firstPaymentMonth,
    Money extraMonthly = Money.zero,
  }) {
    final rows = schedule(
      balance: balance,
      terms: terms,
      firstPaymentMonth: firstPaymentMonth,
      extraMonthly: extraMonthly,
    );
    if (rows == null) return const LoanProjection.unpayable();
    final months = rows.length;
    return LoanProjection.payable(
      months: months,
      totalInterest: Money.sum(rows.map((r) => r.interest)),
      totalFees: terms.monthlyFees.times(months),
      payoffMonth: rows.isEmpty ? firstPaymentMonth : rows.last.month,
    );
  }

  /// Tabla de pagos cuota a cuota desde [balance] (como la proyección del
  /// banco). [firstNumber] numera la primera fila. `null` si la cuota no
  /// alcanza a cubrir los intereses.
  List<LoanInstallment>? schedule({
    required Money balance,
    required LoanTerms terms,
    required YearMonth firstPaymentMonth,
    Money extraMonthly = Money.zero,
    int? firstNumber,
  }) {
    final rate = terms.rate.monthlyEffective;
    final capacity = terms.paymentWithoutFees + extraMonthly;
    final rows = <LoanInstallment>[];
    var remaining = balance;
    while (remaining.isPositive) {
      if (rows.length == maxMonths) return null;
      final interest = remaining.times(rate);
      final available = capacity - interest;
      if (!available.isPositive) return null;
      final principal = available.min(remaining);
      remaining -= principal;
      rows.add(
        LoanInstallment(
          number: firstNumber == null ? null : firstNumber + rows.length,
          month: firstPaymentMonth.addMonths(rows.length),
          payment: principal + interest,
          principal: principal,
          interest: interest,
          balance: remaining,
        ),
      );
    }
    return rows;
  }

  /// Simula pagar [extraMonthly] adicional cada mes. No modifica nada.
  LoanComparison compareExtraPayment({
    required Money balance,
    required LoanTerms terms,
    required YearMonth firstPaymentMonth,
    required Money extraMonthly,
  }) => LoanComparison(
    base: project(
      balance: balance,
      terms: terms,
      firstPaymentMonth: firstPaymentMonth,
    ),
    withExtra: project(
      balance: balance,
      terms: terms,
      firstPaymentMonth: firstPaymentMonth,
      extraMonthly: extraMonthly,
    ),
  );

  /// Tasa efectiva mensual (fracción) con la que [balance] se paga justo en
  /// [months] cuotas de [payment] (sin seguros). Sirve para comparar con el
  /// extracto. `null` si no hay intereses implícitos (cuota × meses ≤ saldo).
  double? impliedMonthlyRate({
    required Money balance,
    required Money payment,
    required int months,
  }) {
    if (months <= 0 || !payment.isPositive || !balance.isPositive) return null;
    if (payment.cents * months <= balance.cents) return null;
    var low = 0.0;
    var high = 1.0;
    for (var i = 0; i < _searchSteps; i++) {
      final mid = (low + high) / 2;
      final installment =
          mid * balance.cents / (1 - math.pow(1 + mid, -months));
      if (installment > payment.cents) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return (low + high) / 2;
  }

  static const _searchSteps = 60;

  /// Parte de un pago que reduce el saldo (descontando cargos e interés).
  Money principalPortion({
    required Money balance,
    required LoanTerms terms,
    required Money payment,
  }) {
    final interest = balance.times(terms.rate.monthlyEffective);
    return (payment - terms.monthlyFees - interest).clamp(Money.zero, balance);
  }
}
