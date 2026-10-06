import 'package:drift/drift.dart';
import 'package:finance_app/domain/shared/date_range.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';
import 'package:finance_app/infrastructure/mappers/transaction_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftTransactionRepository implements TransactionRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(Transaction transaction) => guardStorage(
    'transactions.save',
    () => _db
        .into(_db.transactions)
        .insertOnConflictUpdate(transaction.toCompanion()),
  );

  @override
  Future<void> delete(String id) => guardStorage(
    'transactions.delete',
    () => (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go(),
  );

  @override
  Future<Transaction?> getById(String id) =>
      guardStorage('transactions.getById', () async {
        final query = _db.select(_db.transactions)
          ..where((t) => t.id.equals(id));
        return (await query.getSingleOrNull())?.toDomain();
      });

  @override
  Future<List<Transaction>> getByPeriod(DateRange period) => guardStorage(
    'transactions.getByPeriod',
    () async => _toDomain(await _byPeriod(period).get()),
  );

  @override
  Stream<List<Transaction>> watchByPeriod(DateRange period) =>
      guardStorageStream(
        'transactions.watchByPeriod',
        _byPeriod(period).watch().map(_toDomain),
      );

  @override
  Future<List<Transaction>> getRecent({required int limit}) => guardStorage(
    'transactions.getRecent',
    () async => _toDomain(await _recent(limit).get()),
  );

  @override
  Stream<List<Transaction>> watchRecent({required int limit}) =>
      guardStorageStream(
        'transactions.watchRecent',
        _recent(limit).watch().map(_toDomain),
      );

  SimpleSelectStatement<$TransactionsTable, TransactionRow> _newestFirst() =>
      _db.select(_db.transactions)..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);

  SimpleSelectStatement<$TransactionsTable, TransactionRow> _byPeriod(
    DateRange period,
  ) => _newestFirst()
    ..where(
      (t) =>
          t.date.isBiggerOrEqualValue(period.start) &
          t.date.isSmallerThanValue(period.endExclusive),
    );

  SimpleSelectStatement<$TransactionsTable, TransactionRow> _recent(
    int limit,
  ) => _newestFirst()..limit(limit);

  List<Transaction> _toDomain(List<TransactionRow> rows) =>
      rows.map((row) => row.toDomain()).toList();
}
