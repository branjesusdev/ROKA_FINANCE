import 'package:drift/drift.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';

extension AssetRowMapper on AssetRow {
  Asset toDomain() => Asset(
    id: id,
    name: name,
    type: type,
    currentValue: Money(currentValueCents),
    valuedAt: valuedAt,
    notes: notes,
  );
}

extension AssetCompanionMapper on Asset {
  AssetsCompanion toCompanion() => AssetsCompanion.insert(
    id: id,
    name: name,
    type: type,
    currentValueCents: currentValue.cents,
    valuedAt: valuedAt,
    notes: Value(notes),
  );
}

extension InvestmentRowMapper on InvestmentRow {
  Investment toDomain() => Investment(
    id: id,
    name: name,
    type: type,
    investedAmount: Money(investedCents),
    currentValue: Money(currentValueCents),
    date: date,
    notes: notes,
  );
}

extension InvestmentCompanionMapper on Investment {
  InvestmentsCompanion toCompanion() => InvestmentsCompanion.insert(
    id: id,
    name: name,
    type: type,
    investedCents: investedAmount.cents,
    currentValueCents: currentValue.cents,
    date: date,
    notes: Value(notes),
  );
}
