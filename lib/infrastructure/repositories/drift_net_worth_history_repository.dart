import 'package:drift/drift.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/wealth/net_worth_snapshot.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

final class DriftNetWorthHistoryRepository
    implements NetWorthHistoryRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(NetWorthSnapshot snapshot) => guardStorage(
    'netWorth.save',
    () => _db.transaction(() async {
      // Una foto por mes: la nueva reemplaza a la anterior.
      await (_db.delete(_db.netWorthSnapshots)..where(
            (s) =>
                s.year.equals(snapshot.month.year) &
                s.month.equals(snapshot.month.month),
          ))
          .go();
      await _db
          .into(_db.netWorthSnapshots)
          .insert(
            NetWorthSnapshotsCompanion.insert(
              id: snapshot.id,
              year: snapshot.month.year,
              month: snapshot.month.month,
              assetsCents: snapshot.assets.cents,
              investmentsCents: snapshot.investments.cents,
              liabilitiesCents: snapshot.liabilities.cents,
              takenAt: snapshot.takenAt,
            ),
          );
    }),
  );

  @override
  Stream<List<NetWorthSnapshot>> watchAll() => guardStorageStream(
    'netWorth.watchAll',
    (_db.select(_db.netWorthSnapshots)..orderBy([
          (s) => OrderingTerm.asc(s.year),
          (s) => OrderingTerm.asc(s.month),
        ]))
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              NetWorthSnapshot(
                id: r.id,
                month: YearMonth(r.year, r.month),
                assets: Money(r.assetsCents),
                investments: Money(r.investmentsCents),
                liabilities: Money(r.liabilitiesCents),
                takenAt: r.takenAt,
              ),
          ],
        ),
  );
}
