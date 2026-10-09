import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/cycles/load_current_cycle.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

/// Lo que borraría el reinicio, para confirmarlo antes.
final class CycleResetPreview {
  const new({required this.cycle, required this.removable});

  final PayCycle cycle;

  /// Ingresos y gastos anotados a mano en el ciclo.
  final List<Transaction> removable;
}

/// Empieza el mes de cero: borra los ingresos y gastos anotados en el ciclo
/// actual. Conserva los generados por fijos (arriendo, sueldo… y con ellos
/// el ciclo) y los vinculados a deudas o apartados, cuyos saldos dependen
/// de ellos. La configuración de fijos no se toca.
final class ResetCycleMovements {
  const new({
    required this._currentCycle,
    required this._transactions,
    required this._clock,
  });

  final LoadCurrentCycle _currentCycle;
  final TransactionRepository _transactions;
  final Clock _clock;

  Future<Result<CycleResetPreview>> preview() => guardUseCase(_load);

  /// Devuelve los movimientos borrados (para poder deshacer).
  Future<Result<List<Transaction>>> call() => guardUseCase(() async {
    final removable = (await _load()).removable;
    await _transactions.deleteAll(removable.map((t) => t.id));
    return removable;
  });

  Future<CycleResetPreview> _load() async {
    final current = await _currentCycle(_clock.now());
    return CycleResetPreview(
      cycle: current.cycle,
      removable: [
        for (final t in current.transactions)
          if (!t.isLinked) t,
      ],
    );
  }

  Future<Result<void>> undo(List<Transaction> removed) =>
      guardUseCase(() async {
        for (final t in removed) {
          await _transactions.save(t);
        }
      });
}
