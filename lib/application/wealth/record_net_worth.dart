import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/debts/debt_repository.dart';
import 'package:finance_app/domain/investments/investment_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/wealth/asset_repository.dart';
import 'package:finance_app/domain/wealth/net_worth_calculator.dart';
import 'package:finance_app/domain/wealth/net_worth_snapshot.dart';

/// Guarda la foto del patrimonio del mes actual (al abrir la app). La
/// última del mes es la que queda: así el historial muestra cómo cerró
/// cada mes. Los créditos cuentan una sola vez, como pasivo.
final class RecordNetWorth {
  const new({
    required this._assets,
    required this._investments,
    required this._debts,
    required this._history,
    required this._clock,
    required this._ids,
  });

  final AssetRepository _assets;
  final InvestmentRepository _investments;
  final DebtRepository _debts;
  final NetWorthHistoryRepository _history;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<NetWorthSnapshot>> call() => guardUseCase(() async {
    final now = _clock.now();
    final worth = const NetWorthCalculator().calculate(
      assets: await _assets.getAll(),
      investments: await _investments.getAll(),
      debts: await _debts.getAll(),
    );
    final snapshot = NetWorthSnapshot(
      id: _ids.next(),
      month: YearMonth.fromDate(now),
      assets: worth.assets,
      investments: worth.investments,
      liabilities: worth.liabilities,
      takenAt: now,
    );
    await _history.save(snapshot);
    return snapshot;
  });
}
