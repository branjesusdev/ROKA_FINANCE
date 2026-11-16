import 'package:drift/drift.dart';
import 'package:finance_app/domain/loans/person_loan.dart';
import 'package:finance_app/domain/loans/person_loan_repository.dart';
import 'package:finance_app/infrastructure/mappers/person_loan_mapper.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftPersonLoanRepository implements PersonLoanRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(PersonLoan loan) => guardStorage(
    'personLoans.save',
    () => _db.into(_db.personLoans).insertOnConflictUpdate(loan.toCompanion()),
  );

  @override
  Future<void> delete(String id) => guardStorage(
    'personLoans.delete',
    () => (_db.delete(_db.personLoans)..where((l) => l.id.equals(id))).go(),
  );

  @override
  Stream<List<PersonLoan>> watchAll() {
    final query = _db.select(_db.personLoans)
      ..orderBy([(l) => OrderingTerm.desc(l.date)]);
    return guardStorageStream(
      'personLoans.watchAll',
      query.watch().map((rows) => [for (final r in rows) r.toDomain()]),
    );
  }

  @override
  Stream<List<LoanRepayment>> watchRepayments() => guardStorageStream(
    'personLoans.watchRepayments',
    _db.select(_db.loanRepayments).watch().map(
      (rows) => [for (final r in rows) r.toDomain()],
    ),
  );

  @override
  Future<void> saveRepayment(LoanRepayment repayment) => guardStorage(
    'personLoans.saveRepayment',
    () => _db
        .into(_db.loanRepayments)
        .insertOnConflictUpdate(repayment.toCompanion()),
  );

  @override
  Future<void> deleteRepayment(String id) => guardStorage(
    'personLoans.deleteRepayment',
    () =>
        (_db.delete(_db.loanRepayments)..where((r) => r.id.equals(id))).go(),
  );
}
