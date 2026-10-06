import 'package:drift/drift.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/debt_repository.dart';
import 'package:finance_app/domain/debts/extra_payment.dart';
import 'package:finance_app/infrastructure/mappers/debt_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftDebtRepository implements DebtRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(Debt debt) => guardStorage(
    'debts.save',
    () => _db.into(_db.debts).insertOnConflictUpdate(debt.toCompanion()),
  );

  @override
  Future<void> delete(String id) => guardStorage(
    'debts.delete',
    () => (_db.delete(_db.debts)..where((d) => d.id.equals(id))).go(),
  );

  @override
  Future<Debt?> getById(String id) => guardStorage('debts.getById', () async {
    final query = _db.select(_db.debts)..where((d) => d.id.equals(id));
    return (await query.getSingleOrNull())?.toDomain();
  });

  @override
  Future<List<Debt>> getAll() =>
      guardStorage('debts.getAll', () async => _toDomain(await _all().get()));

  @override
  Stream<List<Debt>> watchAll() =>
      guardStorageStream('debts.watchAll', _all().watch().map(_toDomain));

  @override
  Future<void> saveExtraPayment(ExtraPayment payment) => guardStorage(
    'debts.saveExtraPayment',
    () => _db
        .into(_db.extraPayments)
        .insertOnConflictUpdate(payment.toCompanion()),
  );

  @override
  Future<List<ExtraPayment>> getExtraPayments(String debtId) =>
      guardStorage('debts.getExtraPayments', () async {
        final query = _db.select(_db.extraPayments)
          ..where((p) => p.debtId.equals(debtId))
          ..orderBy([(p) => OrderingTerm.desc(p.date)]);
        return (await query.get()).map((row) => row.toDomain()).toList();
      });

  SimpleSelectStatement<$DebtsTable, DebtRow> _all() =>
      _db.select(_db.debts)..orderBy([(d) => OrderingTerm.asc(d.name)]);

  List<Debt> _toDomain(List<DebtRow> rows) =>
      rows.map((row) => row.toDomain()).toList();
}
