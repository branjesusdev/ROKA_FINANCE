import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/cycles/pay_cycle_resolver.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';
import 'package:finance_app/domain/shared/date_range.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

/// Ciclo real que contiene [CurrentCycle.cycle] (arranca con el sueldo) y
/// sus movimientos.
final class CurrentCycle {
  const new({required this.cycle, required this.transactions});

  final PayCycle cycle;
  final List<Transaction> transactions;
}

/// Resuelve el ciclo actual a partir del día de pago y de los sueldos
/// registrados.
final class LoadCurrentCycle {
  const new({required this._settings, required this._transactions});

  final SettingsRepository _settings;
  final TransactionRepository _transactions;

  Future<CurrentCycle> call(DateTime now) async {
    final settings = await _settings.get();
    final today = DateTime(now.year, now.month, now.day);
    final window = await _transactions.getByPeriod(
      DateRange(
        DateTime(
          today.year,
          today.month,
          today.day - PayCycleResolver.lookbackDays,
        ),
        DateTime(
          today.year,
          today.month,
          today.day + PayCycleResolver.lookaheadDays,
        ),
      ),
    );
    final cycle = PayCycleResolver.fromTransactions(
      payday: settings.payday,
      transactions: window,
    ).containing(today);
    return CurrentCycle(
      cycle: cycle,
      transactions: [
        for (final t in window)
          if (cycle.contains(t.date)) t,
      ],
    );
  }
}
