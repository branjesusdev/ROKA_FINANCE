import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/fixed/fixed_movement_use_cases.dart';
import 'package:finance_app/application/reminders/reminder_planner.dart';
import 'package:finance_app/application/reminders/reminder_scheduler.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/repositories/drift_fixed_movement_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_database.dart';

void main() {
  // La luz vence hoy 13 de octubre y aún no tiene valor real.
  const luz = FixedMovement(
    id: 'luz',
    name: 'Luz',
    kind: TransactionKind.expense,
    amount: Money.pesos(120000),
    categoryId: 'seed-expense-services',
    dayOfMonth: 13,
    isVariable: true,
  );

  List<Reminder> plan(FixedMovement movement, DateTime now) {
    final summary = const CycleSummaryBuilder().build(
      cycle: PayCycle.containing(now, payday: 1),
      today: now,
      cycleTransactions: const [],
      previousCycleTransactions: const [],
      categories: DefaultCategories.all,
      fixedMovements: [movement],
      settings: const FinanceSettings(),
    );
    return const ReminderPlanner()
        .plan(settings: const FinanceSettings(), now: now, summary: summary)
        .where((r) => r.payload == movement.id)
        .toList();
  }

  test('vence hoy: avisa en la tarde y la noche, y sigue mañana', () {
    final reminders = plan(luz, DateTime(2026, 10, 13, 14));
    expect(reminders.map((r) => r.at), [
      DateTime(2026, 10, 13, 15),
      DateTime(2026, 10, 13, 20),
      DateTime(2026, 10, 14, 9),
      DateTime(2026, 10, 14, 15),
      DateTime(2026, 10, 14, 20),
      DateTime(2026, 10, 15, 9),
    ]);
    final bill = reminders.first;
    expect(bill.title, '¿Cuánto llegó la factura de Luz?');
    expect(bill.body, startsWith('Vence hoy'));
    expect(bill.actions, ReminderAction.values);
    expect(reminders[2].body, startsWith('Venció el 13'));
  });

  test('arriendo sin confirmar: pregunta "¿Ya pagaste?" mañana, tarde y '
      'noche', () {
    const rent = FixedMovement(
      id: 'rent',
      name: 'Arriendo',
      kind: TransactionKind.expense,
      amount: Money.pesos(900000),
      categoryId: 'seed-expense-housing',
      dayOfMonth: 13,
    );
    final reminders = plan(rent, DateTime(2026, 10, 13, 7));
    expect(reminders.map((r) => r.at.hour).take(3), [9, 15, 20]);
    expect(reminders.first.title, '¿Ya pagaste Arriendo?');
    expect(reminders.first.actions, ReminderAction.values);

    final auto = plan(
      rent.copyWith(autoDebit: true),
      DateTime(2026, 10, 13, 7),
    );
    expect(auto, isEmpty, reason: 'débito automático: no pregunta');
  });

  test('pospuesta a mañana: avisa mañana a las 9 a. m.', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    final repo = DriftFixedMovementRepository(db);
    await repo.save(luz);
    final snooze = SnoozeFixedBill(
      fixed: repo,
      clock: FixedClock(DateTime(2026, 10, 13, 14)),
    );

    final result = await snooze(movement: luz, days: SnoozeFixedBill.tomorrow);
    final snoozed = (result as Ok<FixedMovement>).value;
    expect(snoozed.remindOn, DateTime(2026, 10, 14));
    expect((await repo.getAll()).single.remindOn, DateTime(2026, 10, 14));
    expect(snoozed.isSnoozedOn(DateTime(2026, 10, 13, 23)), isTrue);
    expect(snoozed.isSnoozedOn(DateTime(2026, 10, 14, 8)), isFalse);

    final reminders = plan(snoozed, DateTime(2026, 10, 13, 14));
    expect(reminders.first.at, DateTime(2026, 10, 14, 9));
    expect(
      reminders.every((r) => !r.at.isBefore(DateTime(2026, 10, 14))),
      isTrue,
      reason: 'nada antes del día pospuesto',
    );
  });
}
