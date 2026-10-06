import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_repository.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

/// Crea (sin `id`) o actualiza un movimiento fijo.
///
/// Al crearlo, si su día ya pasó en el ciclo actual y
/// `registerInCurrentCycle` es `false` (p. ej. ya se anotó a mano), se marca
/// como registrado para no duplicarlo.
final class SaveFixedMovement {
  const new({
    required this._fixed,
    required this._settings,
    required this._clock,
    required this._ids,
  });

  final FixedMovementRepository _fixed;
  final SettingsRepository _settings;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<FixedMovement>> call({
    required String name,
    required TransactionKind kind,
    required Money amount,
    required String categoryId,
    required int dayOfMonth,
    String? id,
    bool isActive = true,
    DateTime? lastPostedOn,
    bool registerInCurrentCycle = true,
  }) {
    final cleanName = cleanText(name);
    if (cleanName == null) return invalid(ValidationCodes.nameRequired);
    if (!amount.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    if (dayOfMonth < FixedMovement.minDay ||
        dayOfMonth > FixedMovement.maxDay) {
      return invalid(ValidationCodes.dayOutOfRange);
    }
    return guardUseCase(() async {
      var lastPosted = lastPostedOn;
      if (id == null && !registerInCurrentCycle) {
        final settings = await _settings.get();
        lastPosted = PayCycle.containing(
          _clock.now(),
          payday: settings.payday,
        ).dateForDayOfMonth(dayOfMonth);
      }
      final movement = FixedMovement(
        id: id ?? _ids.next(),
        name: cleanName,
        kind: kind,
        amount: amount,
        categoryId: categoryId,
        dayOfMonth: dayOfMonth,
        isActive: isActive,
        lastPostedOn: lastPosted,
      );
      await _fixed.save(movement);
      return movement;
    });
  }
}

final class DeleteFixedMovement {
  const new(this._fixed);

  final FixedMovementRepository _fixed;

  Future<Result<void>> call(String id) => guardUseCase(() => _fixed.delete(id));
}

/// Registra como movimientos los fijos cuyo día ya llegó en el ciclo actual.
/// Idempotente: se puede llamar en cada apertura de la app.
final class PostDueFixedMovements {
  const new({
    required this._fixed,
    required this._transactions,
    required this._settings,
    required this._clock,
    required this._ids,
  });

  final FixedMovementRepository _fixed;
  final TransactionRepository _transactions;
  final SettingsRepository _settings;
  final Clock _clock;
  final IdGenerator _ids;

  /// Devuelve cuántos movimientos se registraron.
  Future<Result<int>> call() => guardUseCase(() async {
    final now = _clock.now();
    final settings = await _settings.get();
    final schedule = const FixedMovementScheduler().schedule(
      movements: await _fixed.getAll(),
      cycle: PayCycle.containing(now, payday: settings.payday),
      today: now,
    );
    for (final item in schedule.due) {
      final movement = item.movement;
      await _transactions.save(
        Transaction(
          id: _ids.next(),
          kind: movement.kind,
          amount: movement.amount,
          categoryId: movement.categoryId,
          date: item.date,
          createdAt: now,
          description: movement.name,
          nature: movement.isExpense ? ExpenseNature.essential : null,
        ),
      );
      await _fixed.save(movement.copyWith(lastPostedOn: item.date));
    }
    return schedule.due.length;
  });
}
