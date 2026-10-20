import 'package:finance_app/application/insights/category_report.dart';
import 'package:finance_app/application/transactions/description_suggestions.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/fuel_economy.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const groceries = DefaultCategories.groceries;
  const transportId = FuelEconomyCalculator.transportId;
  final today = DateTime(2026, 10, 12);
  var seq = 0;

  Transaction tx(
    int pesos, {
    required DateTime date,
    String category = 'seed-expense-groceries',
    String? description,
    int? km,
  }) => Transaction(
    id: 't${seq++}',
    kind: TransactionKind.expense,
    amount: Money.pesos(pesos),
    categoryId: category,
    date: date,
    createdAt: date,
    description: description,
    odometerKm: km,
  );

  group('análisis de Mercado', () {
    final history = [
      tx(300000, date: DateTime(2026, 8, 2), description: 'Carne'),
      tx(200000, date: DateTime(2026, 8, 20), description: 'Aseo'),
      tx(150000, date: DateTime(2026, 9, 3), description: 'carne'),
      tx(250000, date: DateTime(2026, 10), description: 'Carne '),
      tx(50000, date: DateTime(2026, 10, 5)),
      tx(999000, date: DateTime(2025, 1, 5), description: 'Viejo'),
      tx(80000, date: DateTime(2026, 10, 6), category: 'otra'),
    ];
    final report = const CategoryReportBuilder().build(
      category: groceries,
      transactions: history,
      today: today,
    );

    test('mes con más gasto, promedio y este mes frente al promedio', () {
      expect(report.months, hasLength(12));
      expect(report.current.month, const YearMonth(2026, 10));
      expect(report.peak!.month, const YearMonth(2026, 8));
      expect(report.peak!.total, const Money.pesos(500000));
      // (500 mil + 150 mil) / 2 meses cerrados con gasto.
      expect(report.monthlyAverage, const Money.pesos(325000));
      expect(report.current.total, const Money.pesos(300000));
      expect(report.currentVsAverage!.isNegative, isTrue);
      expect(report.count, 5, reason: 'sin lo de hace más de un año');
    });

    test('lo que más compras agrupa sin importar mayúsculas', () {
      final top = report.items.first;
      expect(top.name, 'Carne');
      expect(top.total, const Money.pesos(700000));
      expect(top.count, 3);
      expect(report.items.any((i) => i.name == null), isTrue);
      expect(report.biggest!.amount, const Money.pesos(300000));
      expect(report.fuel, isNull, reason: 'Mercado no es de vehículo');
    });
  });

  group('gasolina por km', () {
    test('tanque lleno: lo pagado repone lo recorrido desde la anterior', () {
      final fills = [
        tx(100000, date: DateTime(2026, 9), category: transportId, km: 10000),
        tx(
          120000,
          date: DateTime(2026, 9, 15),
          category: transportId,
          km: 10400,
        ),
        // Error de digitación: no avanza, se ignora.
        tx(90000, date: DateTime(2026, 9, 20), category: transportId, km: 900),
        tx(150000, date: DateTime(2026, 10), category: transportId, km: 10900),
      ];
      final fuel = const FuelEconomyCalculator().compute(fills)!;
      expect(fuel.fills, 3);
      expect(fuel.kmDriven, 900);
      expect(fuel.spent, const Money.pesos(270000));
      expect(fuel.costPerKm, const Money.pesos(300));
      expect(fuel.costPer100Km, const Money.pesos(30000));
      expect(fuel.lastSegmentKm, 500);
      expect(fuel.lastCostPerKm, const Money.pesos(300));
      expect(fuel.kmPerFill, 450);
      expect(fuel.lastVsAverage, Percentage.zero);
    });

    test('solo Transporte o categorías de vehículo piden kilometraje', () {
      final transport = DefaultCategories.expenses.firstWhere(
        (c) => c.id == transportId,
      );
      expect(FuelEconomyCalculator.appliesTo(transport), isTrue);
      expect(FuelEconomyCalculator.appliesTo(groceries), isFalse);
      expect(
        FuelEconomyCalculator.appliesTo(
          const Category(
            id: 'x',
            name: 'Gasolina moto',
            kind: CategoryKind.expense,
            iconKey: 'transport',
          ),
        ),
        isTrue,
      );
    });
  });

  group('sugerencias al escribir', () {
    final history = [
      tx(50000, date: DateTime(2026, 10), description: 'Mercado D1'),
      tx(45000, date: DateTime(2026, 10, 8), description: 'Mercado D1'),
      tx(
        30000,
        date: DateTime(2026, 10, 9),
        description: 'Gasolina',
        category: transportId,
      ),
      tx(9000, date: DateTime(2026, 10, 9), description: 'Café mañana'),
    ];
    List<DescriptionSuggestion> suggest(String q) =>
        const DescriptionSuggestions().suggest(
          query: q,
          kind: TransactionKind.expense,
          history: history,
          categories: DefaultCategories.all,
          fixed: const [
            FixedMovement(
              id: 'f',
              name: 'Gimnasio',
              kind: TransactionKind.expense,
              amount: Money.pesos(90000),
              categoryId: 'seed-expense-groceries',
              dayOfMonth: 5,
            ),
          ],
        );

    test('trae lo ya anotado con su categoría y el último valor', () {
      final result = suggest('merc');
      expect(result, hasLength(1));
      expect(result.single.text, 'Mercado D1');
      expect(result.single.count, 2);
      expect(result.single.lastAmount, const Money.pesos(45000));
      expect(suggest('gas').single.categoryId, transportId);
    });

    test('sin tildes, palabras del medio, fijos y lista corta', () {
      expect(suggest('cafe').single.text, 'Café mañana');
      expect(suggest('d1').single.text, 'Mercado D1');
      expect(suggest('gim').single.isFixed, isTrue);
      expect(suggest(''), isEmpty);
      expect(
        suggest('a').length,
        lessThanOrEqualTo(DescriptionSuggestions.maxResults),
      );
    });
  });
}
