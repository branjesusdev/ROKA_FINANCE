import 'package:drift/drift.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/extra_payment.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';

extension DebtRowMapper on DebtRow {
  Debt toDomain() => Debt(
    id: id,
    name: name,
    type: type,
    originalAmount: Money(originalAmountCents),
    currentBalance: Money(currentBalanceCents),
    notes: notes,
    terms: _terms(),
  );

  LoanTerms? _terms() {
    final basisPoints = rateBasisPoints;
    final type = rateType;
    final payment = monthlyPaymentCents;
    if (basisPoints == null || type == null || payment == null) return null;
    return LoanTerms(
      rate: InterestRate(rate: Percentage.basisPoints(basisPoints), type: type),
      monthlyPayment: Money(payment),
      monthlyFees: Money(monthlyFeesCents ?? 0),
      totalInstallments: totalInstallments,
      paidInstallments: paidInstallments,
      startDate: startDate,
    );
  }
}

extension DebtCompanionMapper on Debt {
  DebtsCompanion toCompanion() {
    final terms = this.terms;
    return DebtsCompanion.insert(
      id: id,
      name: name,
      type: type,
      originalAmountCents: originalAmount.cents,
      currentBalanceCents: currentBalance.cents,
      notes: Value(notes),
      rateBasisPoints: Value(terms?.rate.rate.basisPoints),
      rateType: Value(terms?.rate.type),
      monthlyPaymentCents: Value(terms?.monthlyPayment.cents),
      monthlyFeesCents: Value(terms?.monthlyFees.cents),
      totalInstallments: Value(terms?.totalInstallments),
      paidInstallments: Value(terms?.paidInstallments),
      startDate: Value(terms?.startDate),
    );
  }
}

extension ExtraPaymentRowMapper on ExtraPaymentRow {
  ExtraPayment toDomain() => ExtraPayment(
    id: id,
    debtId: debtId,
    amount: Money(amountCents),
    date: date,
  );
}

extension ExtraPaymentCompanionMapper on ExtraPayment {
  ExtraPaymentsCompanion toCompanion() => ExtraPaymentsCompanion.insert(
    id: id,
    debtId: debtId,
    amountCents: amount.cents,
    date: date,
  );
}
