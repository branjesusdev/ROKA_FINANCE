import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/loans/person_loan.dart';
import 'package:finance_app/domain/loans/person_loan_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';

/// Crea (sin `id`) o actualiza un préstamo con una persona.
final class SavePersonLoan {
  const new({required this._loans, required this._ids});

  final PersonLoanRepository _loans;
  final IdGenerator _ids;

  Future<Result<PersonLoan>> call({
    required String person,
    required LoanDirection direction,
    required Money amount,
    required DateTime date,
    String? id,
    String? note,
  }) {
    final cleanPerson = cleanText(person);
    if (cleanPerson == null) return invalid(ValidationCodes.nameRequired);
    if (!amount.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    final loan = PersonLoan(
      id: id ?? _ids.next(),
      person: cleanPerson,
      direction: direction,
      amount: amount,
      date: date,
      note: cleanText(note),
    );
    return guardUseCase(() async {
      await _loans.save(loan);
      return loan;
    });
  }
}

final class DeletePersonLoan {
  const new(this._loans);

  final PersonLoanRepository _loans;

  Future<Result<void>> call(String id) => guardUseCase(() => _loans.delete(id));
}

/// Abono a un préstamo. Nunca pasa de lo que falta.
final class RegisterLoanRepayment {
  const new({
    required this._loans,
    required this._clock,
    required this._ids,
  });

  final PersonLoanRepository _loans;
  final Clock _clock;
  final IdGenerator _ids;

  /// [balance]: lo que falta hoy del préstamo.
  Future<Result<LoanRepayment>> call({
    required PersonLoan loan,
    required Money balance,
    required Money amount,
    DateTime? date,
  }) {
    if (!amount.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    final repayment = LoanRepayment(
      id: _ids.next(),
      loanId: loan.id,
      amount: amount.min(balance),
      date: date ?? _clock.now(),
    );
    return guardUseCase(() async {
      await _loans.saveRepayment(repayment);
      return repayment;
    });
  }
}

final class DeleteLoanRepayment {
  const new(this._loans);

  final PersonLoanRepository _loans;

  Future<Result<void>> call(String id) =>
      guardUseCase(() => _loans.deleteRepayment(id));
}
