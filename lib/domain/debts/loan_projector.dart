import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';

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
    final rate = terms.rate.monthlyEffective;
    final capacity = terms.paymentWithoutFees + extraMonthly;
    var remaining = balance;
    var months = 0;
    var interest = Money.zero;

    while (remaining.isPositive) {
      if (months == maxMonths) return const LoanProjection.unpayable();
      final monthInterest = remaining.times(rate);
      final principal = capacity - monthInterest;
      if (!principal.isPositive) return const LoanProjection.unpayable();
      interest += monthInterest;
      remaining -= principal.min(remaining);
      months++;
    }

    return LoanProjection.payable(
      months: months,
      totalInterest: interest,
      totalFees: terms.monthlyFees.times(months),
      payoffMonth: firstPaymentMonth.addMonths(months > 0 ? months - 1 : 0),
    );
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
