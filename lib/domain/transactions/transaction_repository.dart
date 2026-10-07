import 'package:finance_app/domain/shared/date_range.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Port de movimientos. Listas ordenadas por fecha descendente.
abstract interface class TransactionRepository {
  Future<void> save(Transaction transaction);

  Future<void> delete(String id);

  Future<Transaction?> getById(String id);

  Future<List<Transaction>> getByPeriod(DateRange period);

  Stream<List<Transaction>> watchByPeriod(DateRange period);

  Future<List<Transaction>> getRecent({required int limit});

  Stream<List<Transaction>> watchRecent({required int limit});

  /// Movimientos de un apartado (todas las fechas).
  Future<List<Transaction>> getLinkedToProvision(String provisionId);

  /// Movimientos vinculados a algún apartado (todas las fechas).
  Stream<List<Transaction>> watchLinkedToProvisions();
}
