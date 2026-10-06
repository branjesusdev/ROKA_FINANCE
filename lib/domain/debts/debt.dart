import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

enum DebtType { bankLoan, creditCard, personalLoan, other }

/// Pasivo. Con [terms] es un crédito proyectable; sin ellas, solo un saldo.
@immutable
final class Debt {
  const new({
    required this.id,
    required this.name,
    required this.type,
    required this.originalAmount,
    required this.currentBalance,
    this.terms,
    this.notes,
  });

  final String id;
  final String name;
  final DebtType type;
  final Money originalAmount;
  final Money currentBalance;
  final LoanTerms? terms;
  final String? notes;

  Money get paidAmount =>
      (originalAmount - currentBalance).clamp(Money.zero, originalAmount);

  bool get isPaidOff => !currentBalance.isPositive;

  /// Tras un pago: nuevo saldo y, si se lleva la cuenta, una cuota más.
  Debt afterPayment(Money newBalance, {bool countsAsInstallment = false}) {
    final terms = this.terms;
    return Debt(
      id: id,
      name: name,
      type: type,
      originalAmount: originalAmount,
      currentBalance: newBalance,
      terms: countsAsInstallment && terms != null
          ? terms.withOneMoreInstallmentPaid()
          : terms,
      notes: notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Debt &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.originalAmount == originalAmount &&
      other.currentBalance == currentBalance &&
      other.terms == terms &&
      other.notes == notes;

  @override
  int get hashCode =>
      Object.hash(id, name, type, originalAmount, currentBalance, terms, notes);
}
