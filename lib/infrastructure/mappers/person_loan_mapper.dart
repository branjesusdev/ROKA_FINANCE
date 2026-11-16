import 'package:drift/drift.dart';
import 'package:finance_app/domain/loans/person_loan.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';

extension PersonLoanRowMapper on PersonLoanRow {
  PersonLoan toDomain() => PersonLoan(
    id: id,
    person: person,
    direction: direction,
    amount: Money(amountCents),
    date: date,
    note: note,
  );
}

extension PersonLoanCompanionMapper on PersonLoan {
  PersonLoansCompanion toCompanion() => PersonLoansCompanion.insert(
    id: id,
    person: person,
    direction: direction,
    amountCents: amount.cents,
    date: date,
    note: Value(note),
  );
}

extension LoanRepaymentRowMapper on LoanRepaymentRow {
  LoanRepayment toDomain() => LoanRepayment(
    id: id,
    loanId: loanId,
    amount: Money(amountCents),
    date: date,
  );
}

extension LoanRepaymentCompanionMapper on LoanRepayment {
  LoanRepaymentsCompanion toCompanion() => LoanRepaymentsCompanion.insert(
    id: id,
    loanId: loanId,
    amountCents: amount.cents,
    date: date,
  );
}
