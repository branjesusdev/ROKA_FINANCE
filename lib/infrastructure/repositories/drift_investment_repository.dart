import 'package:drift/drift.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/investments/investment_repository.dart';
import 'package:finance_app/infrastructure/mappers/wealth_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftInvestmentRepository implements InvestmentRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(Investment investment) => guardStorage(
    'investments.save',
    () => _db
        .into(_db.investments)
        .insertOnConflictUpdate(investment.toCompanion()),
  );

  @override
  Future<void> delete(String id) => guardStorage(
    'investments.delete',
    () => (_db.delete(_db.investments)..where((i) => i.id.equals(id))).go(),
  );

  @override
  Future<List<Investment>> getAll() => guardStorage(
    'investments.getAll',
    () async => _toDomain(await _all().get()),
  );

  @override
  Stream<List<Investment>> watchAll() =>
      guardStorageStream('investments.watchAll', _all().watch().map(_toDomain));

  SimpleSelectStatement<$InvestmentsTable, InvestmentRow> _all() =>
      _db.select(_db.investments)..orderBy([(i) => OrderingTerm.asc(i.name)]);

  List<Investment> _toDomain(List<InvestmentRow> rows) =>
      rows.map((row) => row.toDomain()).toList();
}
