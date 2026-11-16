import 'package:finance_app/domain/loans/person_loan.dart';
import 'package:finance_app/domain/shared/money.dart';

/// Un préstamo con lo abonado y lo que falta.
final class PersonLoanStatus {
  const new({required this.loan, required this.repayments});

  final PersonLoan loan;

  /// Del más reciente al más antiguo.
  final List<LoanRepayment> repayments;

  Money get repaid =>
      Money.sum(repayments.map((r) => r.amount)).min(loan.amount);

  Money get balance => loan.amount - repaid;

  bool get isSettled => !balance.isPositive;

  /// Fracción abonada, de 0 a 1 (para pintar la barra).
  double get progress =>
      loan.amount.isPositive ? repaid.cents / loan.amount.cents : 1;
}

/// "Me deben" y "Debo", con sus totales.
final class PersonLoanOverview {
  const new({required this.lent, required this.borrowed});

  /// Préstamos que hice (pendientes primero, luego los saldados).
  final List<PersonLoanStatus> lent;

  /// Préstamos que me hicieron.
  final List<PersonLoanStatus> borrowed;

  Money get owedToMe => _pending(lent);

  Money get iOwe => _pending(borrowed);

  /// Lo que me deben menos lo que debo.
  Money get net => owedToMe - iOwe;

  bool get isEmpty => lent.isEmpty && borrowed.isEmpty;

  static Money _pending(List<PersonLoanStatus> list) =>
      Money.sum(list.map((s) => s.balance));
}

final class PersonLoanOverviewBuilder {
  const new();

  PersonLoanOverview build({
    required List<PersonLoan> loans,
    required List<LoanRepayment> repayments,
  }) {
    List<PersonLoanStatus> side(LoanDirection direction) {
      final list = [
        for (final loan in loans)
          if (loan.direction == direction)
            PersonLoanStatus(
              loan: loan,
              repayments: [
                for (final r in repayments)
                  if (r.loanId == loan.id) r,
              ]..sort((a, b) => b.date.compareTo(a.date)),
            ),
      ];
      return list..sort((a, b) {
        if (a.isSettled != b.isSettled) return a.isSettled ? 1 : -1;
        return b.loan.date.compareTo(a.loan.date);
      });
    }

    return PersonLoanOverview(
      lent: side(LoanDirection.lent),
      borrowed: side(LoanDirection.borrowed),
    );
  }
}
