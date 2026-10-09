import 'package:finance_app/application/dashboard/spending_radar.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  final cycle = PayCycle.containing(DateTime(2026, 10, 5), payday: 1);
  final previous = cycle.previous;
  // Día 4 del ciclo.
  final today = DateTime(2026, 10, 4, 20);

  SpendingRadar build(
    List<Transaction> current, {
    List<Transaction> before = const [],
  }) => const SpendingRadarBuilder().build(
    cycle: cycle,
    today: today,
    cycleTransactions: current,
    previousCycle: previous,
    previousCycleTransactions: before,
    savingCategoryIds: const {'savings'},
  );

  RadarAxis axis(List<RadarAxis> axes, String key) =>
      axes.singleWhere((a) => a.key == key);

  test('sin gastos variables: vacío', () {
    expect(build(const []).isEmpty, isTrue);
    expect(build([expense(1000, category: 'savings')]).isEmpty, isTrue);
  });

  test('menos de 3 categorías: solo días de la semana', () {
    final radar = build([
      expense(1000, date: DateTime(2026, 10)),
      expense(2000, category: 'transport', date: DateTime(2026, 10, 2)),
    ]);

    expect(radar.byCategory, isEmpty);
    expect(radar.byWeekday, hasLength(7));
    // 1 oct 2026 = jueves.
    expect(axis(radar.byWeekday, '4').current, const Money.pesos(1000));
  });

  test('compara con el ciclo pasado solo en los mismos días', () {
    final radar = build(
      [
        expense(5000, date: DateTime(2026, 10, 2)),
        expense(1000, category: 'transport', date: DateTime(2026, 10, 2)),
        expense(800, category: 'fun', date: DateTime(2026, 10, 3)),
      ],
      before: [
        expense(2000, date: previous.start),
        expense(3000, category: 'transport', date: previous.start),
        // Día 10 del ciclo pasado: fuera de la comparación.
        expense(
          9000,
          date: previous.start.add(const Duration(days: 9)),
        ),
      ],
    );

    expect(radar.hasPrevious, isTrue);
    expect(radar.byCategory.map((a) => a.key), ['food', 'transport', 'fun']);
    final food = axis(radar.byCategory, 'food');
    expect(food.previous, const Money.pesos(2000));
    expect(SpendingRadar.biggestRise(radar.byCategory)?.key, 'food');
    expect(SpendingRadar.biggestDrop(radar.byCategory)?.key, 'transport');
    expect(SpendingRadar.strongest(radar.byCategory)?.key, 'food');
  });

  test('los fijos y el futuro no cuentan', () {
    final fixed = Transaction(
      id: 'rent',
      kind: TransactionKind.expense,
      amount: const Money.pesos(900000),
      categoryId: 'housing',
      date: DateTime(2026, 10),
      createdAt: DateTime(2026, 10),
      fixedMovementId: 'f1',
    );
    final radar = build([
      fixed,
      expense(1000, date: DateTime(2026, 10, 2)),
      expense(7000, category: 'fun', date: DateTime(2026, 10, 20)),
    ]);

    expect(
      Money.sum(radar.byWeekday.map((a) => a.current)),
      const Money.pesos(1000),
    );
  });

  test('máximo 6 categorías, las de más gasto', () {
    final radar = build([
      for (var i = 1; i <= 8; i++)
        expense(i * 1000, category: 'c$i', date: DateTime(2026, 10, 2)),
    ]);

    expect(radar.byCategory, hasLength(SpendingRadarBuilder.maxCategoryAxes));
    expect(radar.byCategory.first.key, 'c8');
    expect(radar.byCategory.map((a) => a.key), isNot(contains('c1')));
  });
}
