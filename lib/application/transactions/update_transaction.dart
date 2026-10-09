import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

final class UpdateTransactionInput {
  const new({
    required this.id,
    required this.kind,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.description,
    this.nature,
  });

  final String id;
  final TransactionKind kind;
  final Money amount;
  final String categoryId;
  final DateTime date;
  final String? description;
  final ExpenseNature? nature;
}

/// Corrige un movimiento ya registrado. Conserva sus vínculos (fijo, deuda,
/// apartado), la cuenta, las notas y la fecha de creación.
final class UpdateTransaction {
  const new(this._transactions);

  final TransactionRepository _transactions;

  Future<Result<Transaction>> call(UpdateTransactionInput input) async {
    if (!input.amount.isPositive) {
      return await invalid(ValidationCodes.amountMustBePositive);
    }
    final found = await guardUseCase(() => _transactions.getById(input.id));
    final Transaction? current;
    switch (found) {
      case Ok(:final value):
        current = value;
      case Err(:final failure):
        return Err(failure);
    }
    if (current == null) {
      return const Err(NotFoundFailure(ValidationCodes.notFound));
    }
    final updated = Transaction(
      id: current.id,
      kind: input.kind,
      amount: input.amount,
      categoryId: input.categoryId,
      date: input.date,
      createdAt: current.createdAt,
      description: cleanText(input.description),
      accountId: current.accountId,
      nature: input.kind == TransactionKind.expense ? input.nature : null,
      notes: current.notes,
      debtId: current.debtId,
      provisionId: current.provisionId,
      fixedMovementId: current.fixedMovementId,
    );
    return await guardUseCase(() async {
      await _transactions.save(updated);
      return updated;
    });
  }
}
