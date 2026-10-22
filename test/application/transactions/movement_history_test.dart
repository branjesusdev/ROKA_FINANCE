import 'package:finance_app/application/transactions/movement_history.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var seq = 0;
  Transaction spend(
    int pesos,
    DateTime date, {
    String category = 'fuel',
    String? description,
  }) => Transaction(
    id: 't${seq++}',
    kind: TransactionKind.expense,
    amount: Money.pesos(pesos),
    categoryId: category,
    date: date,
    createdAt: date,
    description: description,
  );

  final today = DateTime(2026, 10, 20);

  test('compara por descripción cuando se repite y marca el pico', () {
    final target = spend(80000, today, description: 'Gasolina');
    final history = const MovementHistoryBuilder().build(
      target: target,
      today: today,
      transactions: [
        target,
        spend(120000, DateTime(2026, 7, 3), description: 'gasolina '),
        spend(60000, DateTime(2026, 7, 18), description: 'Gasolina'),
        spend(90000, DateTime(2026, 8, 5), description: 'Gasolina'),
        spend(500000, DateTime(2026, 8, 9), description: 'Llantas'),
      ],
    );

    expect(history.basis, MovementHistoryBasis.description);
    expect(history.months, hasLength(12));
    expect(history.peak!.month, const YearMonth(2026, 7));
    expect(history.peak!.total, const Money.pesos(180000));
    expect(history.count, 4);
    expect(history.monthlyAverage, const Money(11666667));
  });

  test('si la descripción no se repite usa la categoría', () {
    final target = spend(80000, today, description: 'Tanqueo viaje');
    final history = const MovementHistoryBuilder().build(
      target: target,
      today: today,
      transactions: [
        target,
        spend(50000, DateTime(2026, 9, 3)),
        spend(70000, DateTime(2026, 9, 3), category: 'food'),
      ],
    );

    expect(history.basis, MovementHistoryBasis.category);
    expect(history.total, const Money.pesos(130000));
    expect(history.hasHistory, isTrue);
  });

  test('reagrupa por toda la categoría aunque la descripción se repita', () {
    final target = spend(
      20000,
      today,
      category: 'food',
      description: 'Almuerzo',
    );
    final all = [
      target,
      spend(
        18000,
        DateTime(2026, 9, 2),
        category: 'food',
        description: 'Almuerzo',
      ),
      spend(
        300000,
        DateTime(2026, 9, 5),
        category: 'food',
        description: 'Mercado',
      ),
    ];
    final mine = const MovementHistoryBuilder().build(
      target: target,
      today: today,
      transactions: all,
    );
    final whole = const MovementHistoryBuilder().build(
      target: target,
      today: today,
      transactions: all,
      basis: MovementHistoryBasis.category,
    );

    expect(mine.basis, MovementHistoryBasis.description);
    expect(mine.total, const Money.pesos(38000));
    expect(whole.basis, MovementHistoryBasis.category);
    expect(whole.canGroupByDescription, isTrue);
    expect(whole.total, const Money.pesos(338000));
  });

  test('tendencia: últimos 3 meses cerrados contra los 3 anteriores', () {
    final target = spend(1000, today);
    final history = const MovementHistoryBuilder().build(
      target: target,
      today: today,
      transactions: [
        target,
        for (final month in [4, 5, 6]) spend(100000, DateTime(2026, month, 10)),
        for (final month in [7, 8, 9]) spend(150000, DateTime(2026, month, 10)),
      ],
    );

    expect(history.trend, const Percentage.whole(50));
    expect(history.lowest!.month, const YearMonth(2026, 10));
  });
}
