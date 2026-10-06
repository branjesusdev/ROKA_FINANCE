import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/loan_projector.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';

/// Resumen de un crédito: proyección actual y, opcionalmente, la simulación
/// de un abono mensual adicional (sin modificar el crédito real).
final class DebtOverview {
  const new _({
    required this.debt,
    required this.projection,
    required this.simulation,
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
    final firstPaymentMonth = currentMonth.next;
    return DebtOverview._(
      debt: debt,
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

  final Debt debt;

  /// `null` si la deuda no tiene condiciones de crédito.
  final LoanProjection? projection;
  final LoanComparison? simulation;

  bool get hasTerms => debt.terms != null;
}
