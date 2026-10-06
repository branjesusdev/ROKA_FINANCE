import 'package:finance_app/domain/investments/investment.dart';

abstract interface class InvestmentRepository {
  Future<void> save(Investment investment);

  Future<void> delete(String id);

  Future<List<Investment>> getAll();

  Stream<List<Investment>> watchAll();
}
