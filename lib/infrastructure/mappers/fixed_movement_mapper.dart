import 'package:drift/drift.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';

extension FixedMovementRowMapper on FixedMovementRow {
  FixedMovement toDomain() => FixedMovement(
    id: id,
    name: name,
    kind: kind,
    amount: Money(amountCents),
    categoryId: categoryId,
    dayOfMonth: dayOfMonth,
    isActive: isActive,
    lastPostedOn: lastPostedOn,
  );
}

extension FixedMovementCompanionMapper on FixedMovement {
  FixedMovementsCompanion toCompanion() => FixedMovementsCompanion.insert(
    id: id,
    name: name,
    kind: kind,
    amountCents: amount.cents,
    categoryId: categoryId,
    dayOfMonth: dayOfMonth,
    isActive: isActive,
    lastPostedOn: Value(lastPostedOn),
  );
}
