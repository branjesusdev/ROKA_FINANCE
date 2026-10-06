import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/debt_repository.dart';
import 'package:finance_app/domain/debts/extra_payment.dart';
import 'package:finance_app/domain/debts/loan_projector.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

/// Crea (sin `id`) o actualiza una deuda/crédito.
final class SaveDebt {
  const new({required this._debts, required this._ids});

  final DebtRepository _debts;
  final IdGenerator _ids;

  Future<Result<Debt>> call({
    required String name,
    required DebtType type,
    required Money originalAmount,
    required Money currentBalance,
    String? id,
    LoanTerms? terms,
    String? notes,
  }) {
    final cleanName = cleanText(name);
    if (cleanName == null) return invalid(ValidationCodes.nameRequired);
    if (!originalAmount.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    if (currentBalance.isNegative) {
      return invalid(ValidationCodes.amountMustNotBeNegative);
    }
    if (terms != null && !terms.monthlyPayment.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    final debt = Debt(
      id: id ?? _ids.next(),
      name: cleanName,
      type: type,
      originalAmount: originalAmount,
      currentBalance: currentBalance,
      terms: terms,
      notes: cleanText(notes),
    );
    return guardUseCase(() async {
      await _debts.save(debt);
      return debt;
    });
  }
}

final class DeleteDebt {
  const new(this._debts);

  final DebtRepository _debts;

  Future<Result<void>> call(String id) => guardUseCase(() => _debts.delete(id));
}

/// Pago de la cuota: queda como gasto (categoría Deudas) y reduce el saldo
/// solo en la parte que abona a capital.
final class RegisterDebtPayment {
  const new({
    required this._debts,
    required this._transactions,
    required this._clock,
    required this._ids,
  });

  final DebtRepository _debts;
  final TransactionRepository _transactions;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<Debt>> call({
    required Debt debt,
    required Money amount,
    DateTime? date,
  }) {
    if (!amount.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    final terms = debt.terms;
    final principal = terms == null
        ? amount.min(debt.currentBalance)
        : const LoanProjector().principalPortion(
            balance: debt.currentBalance,
            terms: terms,
            payment: amount,
          );
    final updated = debt.afterPayment(
      debt.currentBalance - principal,
      countsAsInstallment: true,
    );
    final now = _clock.now();
    return guardUseCase(() async {
      await _transactions.save(
        Transaction(
          id: _ids.next(),
          kind: TransactionKind.expense,
          amount: amount,
          categoryId: DefaultCategories.debtsId,
          date: date ?? now,
          createdAt: now,
          description: 'Cuota ${debt.name}',
          nature: ExpenseNature.essential,
          debtId: debt.id,
        ),
      );
      await _debts.save(updated);
      return updated;
    });
  }
}

/// Abono extraordinario: 100% a capital. También queda como gasto.
final class RegisterExtraPayment {
  const new({
    required this._debts,
    required this._transactions,
    required this._clock,
    required this._ids,
  });

  final DebtRepository _debts;
  final TransactionRepository _transactions;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<Debt>> call({
    required Debt debt,
    required Money amount,
    DateTime? date,
  }) {
    if (!amount.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    final applied = amount.min(debt.currentBalance);
    final updated = debt.afterPayment(debt.currentBalance - applied);
    final now = _clock.now();
    final paymentDate = date ?? now;
    return guardUseCase(() async {
      await _debts.saveExtraPayment(
        ExtraPayment(
          id: _ids.next(),
          debtId: debt.id,
          amount: applied,
          date: paymentDate,
        ),
      );
      await _transactions.save(
        Transaction(
          id: _ids.next(),
          kind: TransactionKind.expense,
          amount: applied,
          categoryId: DefaultCategories.debtsId,
          date: paymentDate,
          createdAt: now,
          description: 'Abono extra ${debt.name}',
          debtId: debt.id,
        ),
      );
      await _debts.save(updated);
      return updated;
    });
  }
}
