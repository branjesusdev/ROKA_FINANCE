import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

/// Condiciones de un crédito con cuota fija (amortización francesa).
@immutable
final class LoanTerms {
  const new({
    required this.rate,
    required this.monthlyPayment,
    this.monthlyFees = Money.zero,
    this.totalInstallments,
    this.paidInstallments,
    this.startDate,
  });

  final InterestRate rate;

  /// Cuota total que paga el usuario cada mes, incluidos seguros/comisiones.
  final Money monthlyPayment;

  /// Seguros y comisiones incluidos en la cuota; no abonan a capital.
  final Money monthlyFees;
  final int? totalInstallments;
  final int? paidInstallments;
  final DateTime? startDate;

  /// Parte de la cuota disponible para intereses + capital.
  Money get paymentWithoutFees => monthlyPayment - monthlyFees;

  /// Cuotas pendientes según el registro del usuario (no la proyección).
  int? get recordedRemainingInstallments {
    final total = totalInstallments;
    final paid = paidInstallments;
    return total == null || paid == null
        ? null
        : (total - paid).clamp(0, total);
  }

  /// Incrementa las cuotas pagadas solo si el usuario las registra.
  LoanTerms withOneMoreInstallmentPaid() {
    final paid = paidInstallments;
    return paid == null
        ? this
        : LoanTerms(
            rate: rate,
            monthlyPayment: monthlyPayment,
            monthlyFees: monthlyFees,
            totalInstallments: totalInstallments,
            paidInstallments: paid + 1,
            startDate: startDate,
          );
  }

  @override
  bool operator ==(Object other) =>
      other is LoanTerms &&
      other.rate == rate &&
      other.monthlyPayment == monthlyPayment &&
      other.monthlyFees == monthlyFees &&
      other.totalInstallments == totalInstallments &&
      other.paidInstallments == paidInstallments &&
      other.startDate == startDate;

  @override
  int get hashCode => Object.hash(
    rate,
    monthlyPayment,
    monthlyFees,
    totalInstallments,
    paidInstallments,
    startDate,
  );
}
