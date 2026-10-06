import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

/// Elimina un movimiento y permite deshacerlo.
final class DeleteTransaction {
  const new(this._transactions);

  final TransactionRepository _transactions;

  Future<Result<void>> call(String id) =>
      guardUseCase(() => _transactions.delete(id));

  Future<Result<void>> undo(Transaction deleted) =>
      guardUseCase(() => _transactions.save(deleted));
}
