import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/provisions/provision_planner.dart';
import 'package:finance_app/domain/provisions/provision_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

/// Crea (sin `id`) o actualiza un apartado.
final class SaveProvision {
  const new({required this._provisions, required this._ids});

  final ProvisionRepository _provisions;
  final IdGenerator _ids;

  Future<Result<Provision>> call({
    required String name,
    required Money amount,
    required int everyMonths,
    required DateTime nextDue,
    required String categoryId,
    String? id,
    bool isActive = true,
  }) {
    final cleanName = cleanText(name);
    if (cleanName == null) return invalid(ValidationCodes.nameRequired);
    if (!amount.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    if (everyMonths < Provision.minMonths ||
        everyMonths > Provision.maxMonths) {
      return invalid(ValidationCodes.monthsOutOfRange);
    }
    final provision = Provision(
      id: id ?? _ids.next(),
      name: cleanName,
      amount: amount,
      everyMonths: everyMonths,
      nextDue: DateTime(nextDue.year, nextDue.month, nextDue.day),
      categoryId: categoryId,
      isActive: isActive,
    );
    return guardUseCase(() async {
      await _provisions.save(provision);
      return provision;
    });
  }
}

final class DeleteProvision {
  const new(this._provisions);

  final ProvisionRepository _provisions;

  Future<Result<void>> call(String id) =>
      guardUseCase(() => _provisions.delete(id));
}

/// Aparta plata (positivo) o la devuelve a la billetera (negativo).
/// Apartar = gasto en la categoría Apartados (cuenta como ahorro, no como
/// gasto); devolver = ajuste de saldo.
final class SetAsideForProvision {
  const new({
    required this._transactions,
    required this._clock,
    required this._ids,
  });

  final TransactionRepository _transactions;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<void>> call({
    required Provision provision,
    required Money amount,
  }) {
    if (amount.isZero) return invalid(ValidationCodes.amountMustNotBeZero);
    final now = _clock.now();
    final deposit = amount.isPositive;
    return guardUseCase(
      () => _transactions.save(
        Transaction(
          id: _ids.next(),
          kind: deposit ? TransactionKind.expense : TransactionKind.income,
          amount: amount.abs,
          categoryId: deposit
              ? DefaultCategories.provisions.id
              : DefaultCategories.balanceAdjustment.id,
          date: now,
          createdAt: now,
          description: deposit
              ? 'Apartado: ${provision.name}'
              : 'Devuelto del apartado: ${provision.name}',
          provisionId: provision.id,
        ),
      ),
    );
  }
}

/// Ya se pagó: usa lo apartado (vuelve a la billetera como ajuste), anota
/// el gasto real en su categoría y mueve la fecha al siguiente pago. Si
/// lo apartado no alcanzó, la diferencia sale del ciclo actual; si sobró,
/// queda para el próximo pago.
final class PayProvision {
  const new({
    required this._provisions,
    required this._transactions,
    required this._clock,
    required this._ids,
  });

  final ProvisionRepository _provisions;
  final TransactionRepository _transactions;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<Provision>> call({required Provision provision, Money? paid}) {
    final amount = paid ?? provision.amount;
    if (!amount.isPositive) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    final now = _clock.now();
    return guardUseCase(() async {
      final linked = await _transactions.getLinkedToProvision(provision.id);
      final saved = Money.sum(
        linked.map(
          (t) => ProvisionPlanner.isDeposit(t)
              ? t.amount
              : ProvisionPlanner.isWithdrawal(t)
              ? -t.amount
              : Money.zero,
        ),
      );
      final used = saved.min(amount);
      if (used.isPositive) {
        await _transactions.save(
          Transaction(
            id: _ids.next(),
            kind: TransactionKind.income,
            amount: used,
            categoryId: DefaultCategories.balanceAdjustment.id,
            date: now,
            createdAt: now,
            description: 'Sale del apartado: ${provision.name}',
            provisionId: provision.id,
          ),
        );
      }
      await _transactions.save(
        Transaction(
          id: _ids.next(),
          kind: TransactionKind.expense,
          amount: amount,
          categoryId: provision.categoryId,
          date: now,
          createdAt: now,
          description: provision.name,
          nature: ExpenseNature.essential,
          provisionId: provision.id,
        ),
      );
      final updated = provision.copyWith(nextDue: provision.followingDue);
      await _provisions.save(updated);
      return updated;
    });
  }
}
