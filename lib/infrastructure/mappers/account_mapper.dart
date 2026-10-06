import 'package:finance_app/domain/accounts/account.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';

extension AccountRowMapper on AccountRow {
  Account toDomain() => Account(id: id, name: name, type: type);
}

extension AccountCompanionMapper on Account {
  AccountsCompanion toCompanion() =>
      AccountsCompanion.insert(id: id, name: name, type: type);
}
