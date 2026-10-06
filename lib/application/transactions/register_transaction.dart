import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

final class RegisterTransactionInput {
  const new({
    required this.kind,
    required this.amount,
    required this.categoryId,
    this.date,
    this.description,
    this.accountId,
    this.nature,
    this.notes,
    this.debtId,
  });

  final TransactionKind kind;
  final Money amount;
  final String categoryId;

  /// Por defecto, ahora.
  final DateTime? date;
  final String? description;
  final String? accountId;
  final ExpenseNature? nature;
  final String? notes;
  final String? debtId;
}

/// Registra un ingreso o gasto. Solo monto y categoría son obligatorios.
final class RegisterTransaction {
  const new({
    required this._transactions,
    required this._clock,
    required this._ids,
  });

  final TransactionRepository _transactions;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<Transaction>> call(RegisterTransactionInput input) {
    if (!input.amount.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    final now = _clock.now();
    final transaction = Transaction(
      id: _ids.next(),
      kind: input.kind,
      amount: input.amount,
      categoryId: input.categoryId,
      date: input.date ?? now,
      createdAt: now,
      description: cleanText(input.description),
      accountId: input.accountId,
      nature: input.kind == TransactionKind.expense ? input.nature : null,
      notes: cleanText(input.notes),
      debtId: input.debtId,
    );
    return guardUseCase(() async {
      await _transactions.save(transaction);
      return transaction;
    });
  }
}
