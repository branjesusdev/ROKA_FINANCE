import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';

extension ProvisionRowMapper on ProvisionRow {
  Provision toDomain() => Provision(
    id: id,
    name: name,
    amount: Money(amountCents),
    everyMonths: everyMonths,
    nextDue: nextDue,
    categoryId: categoryId,
    isActive: isActive,
  );
}

extension ProvisionCompanionMapper on Provision {
  ProvisionsCompanion toCompanion() => ProvisionsCompanion.insert(
    id: id,
    name: name,
    amountCents: amount.cents,
    everyMonths: everyMonths,
    nextDue: nextDue,
    categoryId: categoryId,
    isActive: isActive,
  );
}
