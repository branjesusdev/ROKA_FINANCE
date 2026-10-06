import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/drift_asset_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_category_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_investment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());

  test('activos: guarda, actualiza y borra', () async {
    final repository = DriftAssetRepository(db);
    final car = Asset(
      id: 'a1',
      name: 'Carro',
      type: AssetType.vehicle,
      currentValue: const Money.pesos(45000000),
      valuedAt: DateTime(2026, 10),
      notes: 'Avalúo',
    );

    await repository.save(car);
    expect(await repository.getAll(), [car]);

    await repository.delete('a1');
    expect(await repository.getAll(), isEmpty);
  });

  test('inversiones: guarda y recupera', () async {
    final repository = DriftInvestmentRepository(db);
    final fund = Investment(
      id: 'i1',
      name: 'Fondo',
      type: InvestmentType.fund,
      investedAmount: const Money.pesos(2000000),
      currentValue: const Money.pesos(2150000),
      date: DateTime(2026, 3),
    );

    await repository.save(fund);

    expect(await repository.getAll(), [fund]);
  });

  test('categorías archivadas se excluyen por defecto', () async {
    final repository = DriftCategoryRepository(db);
    final food = (await repository.getById('seed-expense-food'))!;

    await repository.save(food.copyWith(isArchived: true));

    final active = await repository.getAll();
    final all = await repository.getAll(includeArchived: true);
    expect(active.map((c) => c.id), isNot(contains(food.id)));
    expect(all, hasLength(active.length + 1));
    expect(
      active.first.kind,
      CategoryKind.expense,
      reason: 'ordenadas por tipo y orden',
    );
  });
}
