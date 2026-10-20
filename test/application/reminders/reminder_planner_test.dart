import 'package:finance_app/application/advisor/financial_alerts.dart';
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
    expect(morning.body, contains('¿Puedo gastar'));

    final wisdom = byId(reminders, ReminderPlanner.wisdomFirstId);
    expect(wisdom.at, DateTime(2026, 10, 4, 6, 30));
    expect(wisdom.title, 'Frase del día: escríbela');
    expect(wisdom.body, contains('—'), reason: 'incluye la fuente');
    expect(wisdom.body, contains('Hoy: '));
    expect(wisdom.body, endsWith(ReminderPlanner.writeItDown));

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
      hasLength(ReminderPlanner.morningDays * 2),
      reason: 'resumen de la mañana y frase del día, una semana',
    );
  });

  group('avisos de fijos con la lista completa', () {
    const quota = FixedMovement(
      id: 'quota',
      name: 'Cuota carro',
      kind: TransactionKind.expense,
      amount: Money.pesos(1288000),
      categoryId: 'seed-expense-debts',
      dayOfMonth: 20,
    );

    List<Reminder> fixedNotices(List<FixedMovement> fixed, DateTime at) =>
        planner
            .plan(
              settings: const FinanceSettings(),
              now: at,
              fixedMovements: fixed,
            )
            .where(
              (r) =>
                  r.id >= ReminderPlanner.fixedFirstId &&
                  r.id < ReminderPlanner.paydayId,
            )
            .toList();

    test('avisa aunque el pago caiga en el próximo ciclo y sin resumen', () {
      // Ciclo del 20 sep al 19 oct: la cuota del 20 oct es del siguiente.
      final notices = fixedNotices([quota], now);
      expect(notices.map((r) => r.at), [
        DateTime(2026, 10, 19, 19),
        DateTime(2026, 10, 20, 8),
      ]);
      expect(notices.last.title, 'Hoy toca pagar: Cuota carro');
    });

    test('débito automático: el día del pago avisa aunque ya se haya '
        'registrado solo', () {
      final morning = DateTime(2026, 10, 20, 6);
      final posted = quota.copyWith(
        autoDebit: true,
        lastPostedOn: DateTime(2026, 10, 20),
      );
      final notices = fixedNotices([posted], morning);
      expect(notices.first.at, DateTime(2026, 10, 20, 8));
      expect(notices.first.title, 'Hoy toca pagar: Cuota carro');
      // Y sigue con el del mes siguiente.
      expect(notices.last.at, DateTime(2026, 11, 20, 8));
    });

    test('ya confirmado ("Ya lo pagué") no vuelve a avisar ese día', () {
      final morning = DateTime(2026, 10, 20, 6);
      final paid = quota.copyWith(lastPostedOn: DateTime(2026, 10, 20));
      final notices = fixedNotices([paid], morning);
      expect(notices.first.at, DateTime(2026, 11, 19, 19));
    });

    test('pausado no avisa', () {
      expect(fixedNotices([quota.copyWith(isActive: false)], now), isEmpty);
    });
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

  group('resumen de alertas', () {
    FinancialAlert alert(String title, AlertSeverity severity) =>
        FinancialAlert(
          key: title,
          kind: AlertKind.overBudget,
          severity: severity,
          title: title,
          detail: '',
          action: 'Haz algo',
        );

    test('un solo aviso a las 8 p. m. con lo urgente', () {
      final reminders = planner.plan(
        settings: const FinanceSettings(),
        now: now,
        alerts: [
          alert('Te faltan para el arriendo', AlertSeverity.critical),
          alert('Comida subió', AlertSeverity.warning),
          alert('Deuda cara', AlertSeverity.info),
        ],
      );
      final digest = reminders.where(
        (r) => r.id == ReminderPlanner.alertsDigestId,
      );
      expect(digest.single.title, 'Te faltan para el arriendo');
      expect(digest.single.body, contains('Comida subió'));
      expect(digest.single.body, isNot(contains('Deuda cara')));
      expect(digest.single.at.hour, ReminderPlanner.alertsDigestHour);
    });

    test('sin nada urgente no avisa', () {
      final reminders = planner.plan(
        settings: const FinanceSettings(),
        now: now,
        alerts: [alert('Deuda cara', AlertSeverity.info)],
      );
      expect(
        reminders.map((r) => r.id),
        isNot(contains(ReminderPlanner.alertsDigestId)),
      );
    });
  });
}
