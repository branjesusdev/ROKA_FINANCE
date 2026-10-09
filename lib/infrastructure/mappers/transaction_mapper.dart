import 'package:drift/drift.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';

extension TransactionRowMapper on TransactionRow {
  Transaction toDomain() => Transaction(
    id: id,
    kind: kind,
    amount: Money(amountCents),
    categoryId: categoryId,
    date: date,
    createdAt: createdAt,
    description: description,
    accountId: accountId,
    nature: nature,
    notes: notes,
    debtId: debtId,
    provisionId: provisionId,
    fixedMovementId: fixedMovementId,
  );
}

extension TransactionCompanionMapper on Transaction {
  // Los opcionales usan Value(x) aunque sean null: así un upsert también
  // limpia campos borrados por el usuario.
  TransactionsCompanion toCompanion() => TransactionsCompanion.insert(
    id: id,
    kind: kind,
    amountCents: amount.cents,
    categoryId: categoryId,
    date: date,
    createdAt: createdAt,
    description: Value(description),
    accountId: Value(accountId),
    nature: Value(nature),
    notes: Value(notes),
    debtId: Value(debtId),
    provisionId: Value(provisionId),
    fixedMovementId: Value(fixedMovementId),
  );
}
