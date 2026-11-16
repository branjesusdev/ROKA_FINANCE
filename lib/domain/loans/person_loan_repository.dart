import 'package:finance_app/domain/loans/person_loan.dart';

abstract interface class PersonLoanRepository {
  Future<void> save(PersonLoan loan);

  /// Elimina el préstamo y sus abonos.
  Future<void> delete(String id);

  Stream<List<PersonLoan>> watchAll();

  Stream<List<LoanRepayment>> watchRepayments();

  Future<void> saveRepayment(LoanRepayment repayment);

  Future<void> deleteRepayment(String id);
}
