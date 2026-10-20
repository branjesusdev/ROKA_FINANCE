import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/dashboard/spend_check.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';

void main() {
  final today = DateTime(2026, 10, 3, 18);
  final cycle = PayCycle.containing(today, payday: 20);
  final summary = const CycleSummaryBuilder().build(
    cycle: cycle,
    today: today,
    cycleTransactions: [
      income(
        3400000,
        category: DefaultCategories.salaryId,
        date: DateTime(2026, 9, 20),
      ),
    ],
    previousCycleTransactions: const [],
    categories: DefaultCategories.all,
    fixedMovements: const [],
    settings: const FinanceSettings(),
  );

  SpendCheck check(int pesos) => const SpendCheckBuilder().build(
    summary: summary,
    amount: Money.pesos(pesos),
  )!;

  test('un gasto pequeño cabe en el tope de hoy y no cambia los días', () {
    final cap = summary.dailyCap!.cap;
    final result = check(cap.cents ~/ Money.centsPerPeso ~/ 2);
    expect(result.verdict, SpendVerdict.fitsToday);
    expect(result.payAll.dailyCut, Money.zero);
    expect(result.daysAfterToday, 16);
  });

  test('600 mil: se puede gastando menos los días que siguen', () {
    final result = check(600000);
    expect(result.verdict, SpendVerdict.fitsWithRecovery);
    final after = result.payAll.dailyCapAfter!;
    expect(after, lessThan(result.capToday));
    // Lo libre se reparte: gasto + días que siguen × nuevo tope ≈ libre.
    expect(
      (result.freeLeft - result.amount - after.times(16.0)).cents.abs(),
      lessThan(100),
    );
    // Pagar la mitad recorta menos.
    expect(result.payHalf.dailyCut, lessThan(result.payAll.dailyCut));
    expect(result.nextPayday, DateTime(2026, 10, 20));
  });

  test('más de lo libre toca lo apartado y luego los fijos', () {
    final free = check(1).freeLeft;
    final reserved = summary.dailyCap!.reserved;
    final reserves = const SpendCheckBuilder().build(
      summary: summary,
      amount: free + const Money.pesos(1),
    )!;
    expect(
      reserves.verdict,
      reserved.isPositive ? SpendVerdict.usesReserves : SpendVerdict.notEnough,
    );
    final tooMuch = check(10000000);
    expect(tooMuch.verdict, SpendVerdict.notEnough);
    expect(tooMuch.shortfall.isPositive, isTrue);
    expect(tooMuch.fromReserves, reserved);
  });
}
