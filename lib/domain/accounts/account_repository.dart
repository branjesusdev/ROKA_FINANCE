import 'package:finance_app/domain/accounts/account.dart';

abstract interface class AccountRepository {
  Future<void> save(Account account);

  Future<List<Account>> getAll();

  Stream<List<Account>> watchAll();
}
