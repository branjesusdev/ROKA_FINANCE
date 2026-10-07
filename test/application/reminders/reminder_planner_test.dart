import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/reminders/reminder_planner.dart';
import 'package:finance_app/application/reminders/reminder_scheduler.dart';
import 'package:finance_app/application/reminders/sync_reminders.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';

final class _MemorySettings implements SettingsRepository {
  new(this.value);

  FinanceSettings value;

  @override
  Future<FinanceSettings> get() async => value;

  @override
  Future<void> save(FinanceSettings settings) async => value = settings;

  @override
  Stream<FinanceSettings> watch() => Stream.value(value);
}

void main() {
  final now = DateTime(2026, 10, 3, 10);
  const planner = ReminderPlanner();

  CycleSummary summary() => const CycleSummaryBuilder().build(
    cycle: PayCycle.containing(now, payday: 20),
    today: now,
    cycleTransactions: [
      income(
        3400000,
        category: DefaultCategories.salaryId,
        date: DateTime(2026, 9, 20),
      ),
    ],
    previousCycleTransactions: const [],
    categories: DefaultCategories.all,
    fixedMovements: const [
      FixedMovement(
        id: 'rent',
        name: 'Arriendo',
        kind: TransactionKind.expense,
        amount: Money.pesos(1000000),
        categoryId: 'seed-expense-housing',
        dayOfMonth: 5,
      ),
    ],
    settings: const FinanceSettings(),
  );

  Reminder byId(List<Reminder> reminders, int id) =>
      reminders.singleWhere((r) => r.id == id);

  test('el recordatorio diario respeta los minutos (5:04 p. m.)', () {
    final reminders = planner.plan(
      settings: const FinanceSettings(reminderHour: 17, reminderMinute: 4),
      now: now,
    );

    final daily = byId(reminders, ReminderPlanner.dailyId);
    expect(daily.at, DateTime(2026, 10, 3, 17, 4));
    expect(daily.repeatsDaily, isTrue);
    expect(daily.channel, ReminderChannel.daily);
  });

  test('si la hora ya pasó hoy, el primero es mañana', () {
    final reminders = planner.plan(
      settings: const FinanceSettings(reminderHour: 8),
      now: now,
    );

    expect(
      byId(reminders, ReminderPlanner.dailyId).at,
      DateTime(2026, 10, 4, 8),
    );
  });

  test('avisos inteligentes: tope de mañana, fijo de mañana, cierre y día '
      'de pago', () {
    final reminders = planner.plan(
      settings: const FinanceSettings(),
      now: now,
      summary: summary(),
    );

    final morning = byId(reminders, ReminderPlanner.morningFirstId);
    expect(morning.at, DateTime(2026, 10, 4, 7));
    // Mañana quedan 16 días: (3.400.000 − 1.000.000 − 340.000 de ahorro)/16.
    expect(morning.title, r'Hoy puedes gastar hasta $ 128.750');
    expect(morning.body, contains('—'), reason: 'incluye una frase');

    final rent = byId(reminders, ReminderPlanner.fixedFirstId);
    expect(rent.at, DateTime(2026, 10, 4, 19));
    expect(rent.title, 'Mañana: Arriendo');

    expect(
      byId(reminders, ReminderPlanner.cycleCloseId).at,
      DateTime(2026, 10, 18, 19),
    );
    expect(
      byId(reminders, ReminderPlanner.paydayId).at,
      DateTime(2026, 10, 20, 9),
    );
    expect(
      reminders.where(
        (r) =>
            r.id >= ReminderPlanner.morningFirstId &&
            r.id < ReminderPlanner.fixedFirstId,
      ),
      hasLength(ReminderPlanner.morningDays),
    );
  });

  test('sin avisos inteligentes solo queda el recordatorio', () {
    final reminders = planner.plan(
      settings: const FinanceSettings(smartNotifications: false),
      now: now,
      summary: summary(),
    );

    expect(reminders.map((r) => r.id), [ReminderPlanner.dailyId]);
  });

  test('sincronizar reemplaza lo programado; la prueba muestra uno y '
      'programa otro en un minuto', () async {
    final scheduler = FakeReminderScheduler();
    final clock = FixedClock(now);
    final settings = _MemorySettings(
      const FinanceSettings(smartNotifications: false),
    );

    expect(
      await SyncReminders(
        settings: settings,
        scheduler: scheduler,
        clock: clock,
      ).call(),
      isTrue,
    );
    expect(scheduler.scheduled.map((r) => r.id), [ReminderPlanner.dailyId]);

    await TestReminder(scheduler: scheduler, clock: clock).call();
    expect(scheduler.shown, hasLength(1));
    expect(scheduler.scheduled.last.at, now.add(const Duration(minutes: 1)));
  });
}
