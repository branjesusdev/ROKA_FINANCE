import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

/// Hacia dónde va la plata: la prestaste tú o te la prestaron.
enum LoanDirection { lent, borrowed }

/// Préstamo con una persona (sin intereses): "Me debe Juan", "Le debo a mi
/// mamá". El saldo sale del monto menos los abonos.
@immutable
final class PersonLoan {
  const new({
    required this.id,
    required this.person,
    required this.direction,
    required this.amount,
    required this.date,
    this.note,
  });

  final String id;
  final String person;
  final LoanDirection direction;
  final Money amount;
  final DateTime date;
  final String? note;

  bool get isLent => direction == LoanDirection.lent;

  @override
  bool operator ==(Object other) =>
      other is PersonLoan &&
      other.id == id &&
      other.person == person &&
      other.direction == direction &&
      other.amount == amount &&
      other.date == date &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, person, direction, amount, date, note);
}

/// Abono a un préstamo con una persona.
@immutable
final class LoanRepayment {
  const new({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
  });

  final String id;
  final String loanId;
  final Money amount;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is LoanRepayment &&
      other.id == id &&
      other.loanId == loanId &&
      other.amount == amount &&
      other.date == date;

  @override
  int get hashCode => Object.hash(id, loanId, amount, date);
}
