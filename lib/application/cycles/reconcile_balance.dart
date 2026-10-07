import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/application/cycles/load_current_cycle.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/fixed/fixed_movement_repository.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/insights/cash_flow_calculator.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

/// Resultado del cuadre.
final class ReconcileResult {
  const new({required this.registered, required this.actual});

  /// Lo que la app creía que te quedaba antes de cuadrar.
  final Money registered;

  /// Lo que de verdad tienes.
  final Money actual;

  /// Negativo = gastos que no se anotaron. Positivo = dinero que no estaba
  /// registrado (p. ej. lo que tenías al empezar).
  Money get difference => actual - registered;
}

/// "Cuadrar con mi dinero real": ajusta el ciclo para que "te queda" sea lo
/// que realmente tienes.
///
/// Primero registra los fijos que ya pagaste (aunque su día no haya
/// llegado) y luego anota la diferencia: si falta dinero, como "Gastos sin
/// registrar" (queda en el histórico para mejorar el próximo ciclo); si
/// sobra, como "Saldo inicial / ajuste" (no cuenta como ingreso).
final class ReconcileBalance {
  const new({
    required this._currentCycle,
    required this._transactions,
    required this._fixed,
    required this._clock,
    required this._ids,
  });

  final LoadCurrentCycle _currentCycle;
  final TransactionRepository _transactions;
  final FixedMovementRepository _fixed;
  final Clock _clock;
  final IdGenerator _ids;

  static const description = 'Cuadre con mi dinero real';

  Future<Result<ReconcileResult>> call({
    required Money actual,
    Set<String> paidFixedIds = const {},
  }) {
    if (actual.isNegative) {
      return invalid(ValidationCodes.amountMustNotBeNegative);
    }
    return guardUseCase(() async {
      final now = _clock.now();
      final today = DateTime(now.year, now.month, now.day);
      if (paidFixedIds.isNotEmpty) await _registerPaidFixed(now, paidFixedIds);

      final current = await _currentCycle(now);
      final flow = const CashFlowCalculator().calculate(
        current.transactions,
        savingCategoryIds: const {},
      );
      final registered =
          flow.adjustments +
          flow.income -
          flow.expenses -
          flow.savingContributions;
      final result = ReconcileResult(registered: registered, actual: actual);
      final difference = result.difference;
      if (!difference.isZero) {
        await _transactions.save(
          Transaction(
            id: _ids.next(),
            kind: difference.isNegative
                ? TransactionKind.expense
                : TransactionKind.income,
            amount: difference.abs,
            categoryId: difference.isNegative
                ? DefaultCategories.untracked.id
                : DefaultCategories.balanceAdjustment.id,
            date: today,
            createdAt: now,
            description: description,
          ),
        );
      }
      return result;
    });
  }

  /// Registra hoy los fijos pendientes del ciclo que ya se pagaron.
  Future<void> _registerPaidFixed(DateTime now, Set<String> ids) async {
    final current = await _currentCycle(now);
    final schedule = const FixedMovementScheduler().schedule(
      movements: await _fixed.getAll(),
      cycle: current.cycle,
      today: now,
      cycleTransactions: current.transactions,
    );
    final done = <String>{};
    for (final item in [...schedule.due, ...schedule.upcoming]) {
      final movement = item.movement;
      if (!ids.contains(movement.id) || !done.add(movement.id)) continue;
      await _transactions.save(
        Transaction(
          id: _ids.next(),
          kind: movement.kind,
          amount: movement.amount,
          categoryId: movement.categoryId,
          date: DateTime(now.year, now.month, now.day),
          createdAt: now,
          description: movement.name,
          nature: movement.isExpense ? ExpenseNature.essential : null,
        ),
      );
      await _fixed.save(movement.copyWith(lastPostedOn: item.date));
    }
  }
}
