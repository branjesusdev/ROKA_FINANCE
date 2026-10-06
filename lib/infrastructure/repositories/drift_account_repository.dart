import 'package:drift/drift.dart';
import 'package:finance_app/domain/accounts/account.dart';
import 'package:finance_app/domain/accounts/account_repository.dart';
import 'package:finance_app/infrastructure/mappers/account_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftAccountRepository implements AccountRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(Account account) => guardStorage(
    'accounts.save',
    () => _db.into(_db.accounts).insertOnConflictUpdate(account.toCompanion()),
  );

  @override
  Future<List<Account>> getAll() => guardStorage(
    'accounts.getAll',
    () async => _toDomain(await _all().get()),
  );

  @override
  Stream<List<Account>> watchAll() =>
      guardStorageStream('accounts.watchAll', _all().watch().map(_toDomain));

  SimpleSelectStatement<$AccountsTable, AccountRow> _all() =>
      _db.select(_db.accounts)..orderBy([(a) => OrderingTerm.asc(a.name)]);

  List<Account> _toDomain(List<AccountRow> rows) =>
      rows.map((row) => row.toDomain()).toList();
}
