import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/extra_payment.dart';

abstract interface class DebtRepository {
  Future<void> save(Debt debt);

  /// Elimina la deuda y sus abonos; los movimientos asociados se conservan.
  Future<void> delete(String id);

  Future<Debt?> getById(String id);

  Future<List<Debt>> getAll();

  Stream<List<Debt>> watchAll();

  Future<void> saveExtraPayment(ExtraPayment payment);

  /// Ordenados por fecha descendente.
  Future<List<ExtraPayment>> getExtraPayments(String debtId);
}
