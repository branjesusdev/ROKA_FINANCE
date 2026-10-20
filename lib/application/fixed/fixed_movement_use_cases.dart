import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/application/cycles/load_current_cycle.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/debt_repository.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_repository.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/fixed/variable_bill_estimator.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

/// Crea (sin `id`) o actualiza un movimiento fijo.
///
/// Al crearlo, si su día ya pasó en el ciclo actual y
/// `registerInCurrentCycle` es `false` (ya se pagó: el dinero real ya lo
/// descuenta, o se anotó a mano), se marca como registrado para no
/// duplicarlo.
final class SaveFixedMovement {
  const new({
    required this._fixed,
    required this._currentCycle,
    required this._clock,
    required this._ids,
  });

  final FixedMovementRepository _fixed;
  final LoadCurrentCycle _currentCycle;
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
    bool isVariable = false,
    bool autoDebit = false,
    DateTime? lastPostedOn,
    bool registerInCurrentCycle = true,
    String? debtId,
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
      final existing = id == null
          ? null
          : (await _fixed.getAll()).where((m) => m.id == id).firstOrNull;
      var lastPosted = lastPostedOn;
      if (id == null && !registerInCurrentCycle) {
        final now = _clock.now();
        final today = DateTime(now.year, now.month, now.day);
        final passed = (await _currentCycle(now)).cycle
            .datesForDayOfMonth(dayOfMonth)
            .where((d) => !d.isAfter(today));
        lastPosted = passed.isEmpty ? null : passed.last;
      }
      final movement = FixedMovement(
        id: id ?? _ids.next(),
        name: cleanName,
        kind: kind,
        amount: amount,
        categoryId: categoryId,
        dayOfMonth: dayOfMonth,
        isActive: isActive,
        isVariable: isVariable,
        autoDebit: kind == TransactionKind.expense && autoDebit,
        lastPostedOn: lastPosted,
        debtId: kind == TransactionKind.expense ? debtId : null,
        remindOn: existing?.remindOn,
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

/// Registra el pago de un fijo del ciclo ("Ya lo pagué"): el valor real de
/// una factura variable (luz, agua…), un gasto fijo que venció o uno pagado
/// antes de su día. Lo marca como
/// registrado para que no se duplique. En los variables actualiza el
/// estimado con el promedio de las últimas facturas.
final class ConfirmVariableFixed {
  const new({
    required this._fixed,
    required this._transactions,
    required this._debts,
    required this._clock,
    required this._ids,
  });

  final FixedMovementRepository _fixed;
  final TransactionRepository _transactions;
  final DebtRepository _debts;
  final Clock _clock;
  final IdGenerator _ids;

  /// [scheduledDate]: la fecha del fijo en el ciclo que se confirma.
  Future<Result<Transaction>> call({
    required FixedMovement movement,
    required DateTime scheduledDate,
    required Money amount,
  }) {
    if (!amount.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    return guardUseCase(() async {
      final now = _clock.now();
      final today = DateTime(now.year, now.month, now.day);
      final transaction = Transaction(
        id: _ids.next(),
        kind: movement.kind,
        amount: amount,
        categoryId: movement.categoryId,
        // Factura adelantada: queda en su fecha para no salir del ciclo.
        date: scheduledDate.isAfter(today) ? scheduledDate : today,
        createdAt: now,
        description: movement.name,
        nature: movement.isExpense ? ExpenseNature.essential : null,
        fixedMovementId: movement.id,
        debtId: movement.isExpense ? movement.debtId : null,
      );
      await _transactions.save(transaction);
      await payLinkedDebt(_debts, movement, amount);
      if (!movement.isVariable) {
        await _fixed.save(
          movement.copyWith(lastPostedOn: scheduledDate).remindedOn(null),
        );
        return transaction;
      }
      final recent = await _transactions.getLinkedToFixed(
        movement.id,
        limit: VariableBillEstimator.lastBills,
      );
      final estimate = const VariableBillEstimator().estimate([
        for (final t in recent) t.amount,
      ]);
      await _fixed.save(
        movement
            .copyWith(amount: estimate ?? amount, lastPostedOn: scheduledDate)
            .remindedOn(null),
      );
      return transaction;
    });
  }
}

/// "Aún no lo pago: recuérdame mañana / en 2 días". La factura sigue
/// descontando su estimado; solo deja de avisar hasta ese día.
final class SnoozeFixedBill {
  const new({required this._fixed, required this._clock});

  final FixedMovementRepository _fixed;
  final Clock _clock;

  /// Opciones que ofrecen la app y la notificación.
  static const tomorrow = 1;
  static const inTwoDays = 2;

  Future<Result<FixedMovement>> call({
    required FixedMovement movement,
    required int days,
  }) {
    if (days <= 0) return invalid(ValidationCodes.dayOutOfRange);
    return guardUseCase(() async {
      final now = _clock.now();
      final snoozed = movement.remindedOn(
        DateTime(now.year, now.month, now.day + days),
      );
      await _fixed.save(snoozed);
      return snoozed;
    });
  }
}

/// "Aún no lo he pagado": deshace el pago registrado de un fijo en el ciclo
/// actual. Borra su movimiento y lo deja otra vez por confirmar, con avisos.
/// No aplica a los que pagan un crédito (el saldo ya bajó).
final class MarkFixedUnpaid {
  const new({
    required this._fixed,
    required this._transactions,
    required this._currentCycle,
    required this._clock,
  });

  final FixedMovementRepository _fixed;
  final TransactionRepository _transactions;
  final LoadCurrentCycle _currentCycle;
  final Clock _clock;

  /// [paidOn]: fecha del pago registrado que se deshace.
  Future<Result<FixedMovement>> call({
    required FixedMovement movement,
    required DateTime paidOn,
  }) {
    if (movement.debtId != null) {
      return invalid(ValidationCodes.linkedToDebt);
    }
    return guardUseCase(() async {
      final current = await _currentCycle(_clock.now());
      bool sameDay(DateTime a) =>
          a.year == paidOn.year &&
          a.month == paidOn.month &&
          a.day == paidOn.day;
      for (final t in current.transactions) {
        if (t.fixedMovementId == movement.id && sameDay(t.date)) {
          await _transactions.delete(t.id);
        }
      }
      final dates = current.cycle.datesForDayOfMonth(movement.dayOfMonth);
      final day = DateTime(paidOn.year, paidOn.month, paidOn.day);
      final scheduled =
          dates.where((d) => !d.isAfter(day)).lastOrNull ?? dates.firstOrNull;
      var updated = movement.remindedOn(null);
      if (scheduled != null) {
        final before = dates.where((d) => d.isBefore(scheduled)).lastOrNull;
        updated = FixedMovement(
          id: updated.id,
          name: updated.name,
          kind: updated.kind,
          amount: updated.amount,
          categoryId: updated.categoryId,
          dayOfMonth: updated.dayOfMonth,
          isActive: updated.isActive,
          isVariable: updated.isVariable,
          autoDebit: updated.autoDebit,
          lastPostedOn:
              before ??
              DateTime(scheduled.year, scheduled.month, scheduled.day - 1),
        );
      }
      await _fixed.save(updated);
      return updated;
    });
  }
}

/// Registra como movimientos los fijos cuyo día ya llegó en el ciclo actual.
/// Idempotente: se puede llamar en cada apertura de la app.
///
/// Un ingreso fijo que el usuario ya anotó a mano (sueldo adelantado) se
/// marca como registrado sin duplicarlo.
final class PostDueFixedMovements {
  const new({
    required this._fixed,
    required this._transactions,
    required this._debts,
    required this._currentCycle,
    required this._clock,
    required this._ids,
  });

  final FixedMovementRepository _fixed;
  final TransactionRepository _transactions;
  final DebtRepository _debts;
  final LoadCurrentCycle _currentCycle;
  final Clock _clock;
  final IdGenerator _ids;

  /// Devuelve cuántos movimientos se registraron.
  Future<Result<int>> call() => guardUseCase(() async {
    final now = _clock.now();
    final current = await _currentCycle(now);
    final schedule = const FixedMovementScheduler().schedule(
      movements: await _fixed.getAll(),
      cycle: current.cycle,
      today: now,
      cycleTransactions: current.transactions,
    );
    // Última fecha registrada por fijo (puede tener varias en el ciclo).
    final postedUntil = <String, ScheduledFixed>{};
    void markPosted(ScheduledFixed item) {
      final known = postedUntil[item.movement.id];
      if (known == null || item.date.isAfter(known.date)) {
        postedUntil[item.movement.id] = item;
      }
    }

    schedule.covered.forEach(markPosted);
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
          fixedMovementId: movement.id,
          debtId: movement.isExpense ? movement.debtId : null,
        ),
      );
      await payLinkedDebt(_debts, movement, movement.amount);
      markPosted(item);
    }
    for (final item in postedUntil.values) {
      await _fixed.save(item.movement.copyWith(lastPostedOn: item.date));
    }
    return schedule.due.length;
  });
}

/// Si el fijo paga un crédito, baja su saldo y suma la cuota pagada.
Future<void> payLinkedDebt(
  DebtRepository debts,
  FixedMovement movement,
  Money amount,
) async {
  final id = movement.debtId;
  if (id == null || !movement.isExpense) return;
  final debt = await debts.getById(id);
  if (debt == null || !debt.currentBalance.isPositive) return;
  await debts.save(debt.afterInstallment(amount));
}

/// Enlaza un crédito con su cuota fija: con uno existente (`fixed`) o
/// creando uno nuevo el día `dayOfMonth` por el valor de la cuota.
/// Un crédito queda enlazado a un solo fijo.
final class LinkDebtToFixed {
  const new({required this._fixed, required this._save});

  final FixedMovementRepository _fixed;
  final SaveFixedMovement _save;

  Future<Result<FixedMovement>> call({
    required Debt debt,
    FixedMovement? fixed,
    int? dayOfMonth,
    String? categoryId,
  }) async {
    final unlinked = await guardUseCase(() async {
      for (final other in await _fixed.getAll()) {
        if (other.debtId == debt.id && other.id != fixed?.id) {
          await _fixed.save(other.linkedTo(null));
        }
      }
    });
    if (unlinked case Err(:final failure)) return Err(failure);
    if (fixed != null) {
      return await guardUseCase(() async {
        final linked = fixed.linkedTo(debt.id);
        await _fixed.save(linked);
        return linked;
      });
    }
    final payment = debt.terms?.monthlyPayment;
    if (payment == null || !payment.isPositive) {
      return await invalid(ValidationCodes.amountMustBePositive);
    }
    return await _save(
      name: 'Cuota ${debt.name}',
      kind: TransactionKind.expense,
      amount: payment,
      categoryId: categoryId ?? DefaultCategories.debtsId,
      dayOfMonth: dayOfMonth ?? FixedMovement.minDay,
      // Lo de este ciclo ya lo cuenta el saldo que escribiste.
      registerInCurrentCycle: false,
      debtId: debt.id,
    );
  }

  /// Quita el enlace (el fijo sigue existiendo).
  Future<Result<void>> unlink(FixedMovement fixed) =>
      guardUseCase(() => _fixed.save(fixed.linkedTo(null)));
}
