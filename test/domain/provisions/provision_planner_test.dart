import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/provisions/provision_planner.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const planner = ProvisionPlanner();
  final today = DateTime(2026, 10, 6);
  // Sueldo el 20: ciclo 20 sep → 19 oct (14 días desde hoy).
  final cycle = PayCycle.containing(today, payday: 20);

  Provision provision({
    String id = 'soat',
    int pesos = 447000,
    int everyMonths = 12,
    DateTime? nextDue,
    bool isActive = true,
  }) => Provision(
    id: id,
    name: id,
    amount: Money.pesos(pesos),
    everyMonths: everyMonths,
    nextDue: nextDue ?? DateTime(2026, 11),
    categoryId: 'seed-expense-transport',
    isActive: isActive,
  );

  var sequence = 0;
  Transaction deposit(int pesos, DateTime date) => Transaction(
    id: 'd${sequence++}',
    kind: TransactionKind.expense,
    amount: Money.pesos(pesos),
    categoryId: DefaultCategories.provisions.id,
    date: date,
    createdAt: date,
    provisionId: 'soat',
  );

  Transaction withdrawal(int pesos, DateTime date) => Transaction(
    id: 'w${sequence++}',
    kind: TransactionKind.income,
    amount: Money.pesos(pesos),
    categoryId: DefaultCategories.balanceAdjustment.id,
    date: date,
    createdAt: date,
    provisionId: 'soat',
  );

  ProvisionPlan plan(List<Provision> provisions, [List<Transaction>? linked]) =>
      planner.plan(
        provisions: provisions,
        linked: linked ?? const [],
        cycle: cycle,
        today: today,
      );

  test('SOAT en noviembre sin nada apartado: 2 sueldos y en rojo', () {
    final status = plan([provision()]).statuses.single;

    expect(status.cyclesLeft, 2);
    expect(status.perCycle, const Money.pesos(223500));
    expect(status.pendingThisCycle, const Money.pesos(223500));
    // Apartando parejo, a esta altura irían 10 de 12 partes.
    expect(status.behind, const Money.pesos(372500));
    expect(status.light, TrafficLight.critical);
    expect(status.daysUntilDue, 26);
  });

  test('cuota de hoy = pendiente del ciclo entre los días que quedan', () {
    final result = plan([provision()]);

    expect(result.daysLeft, 14);
    // 223.500 / 14 = 15.964,3 → hacia arriba al peso.
    expect(result.todaySetAside, const Money.pesos(15965));
  });

  test('gimnasio trimestral con tiempo de sobra: verde', () {
    final gym = provision(
      id: 'gym',
      pesos: 199000,
      everyMonths: 3,
      nextDue: DateTime(2026, 12, 20),
    );
    final status = plan([gym]).statuses.single;

    expect(status.cyclesLeft, 4);
    expect(status.perCycle, const Money.pesos(49750));
    expect(status.behind, Money.zero);
    expect(status.light, TrafficLight.ok);
  });

  test('lo apartado en este ciclo baja lo pendiente, no la cuota', () {
    final status = plan(
      [provision()],
      [deposit(100000, DateTime(2026, 10, 2))],
    ).statuses.single;

    expect(status.perCycle, const Money.pesos(223500));
    expect(status.setAsideThisCycle, const Money.pesos(100000));
    expect(status.pendingThisCycle, const Money.pesos(123500));
  });

  test('lo apartado antes del ciclo baja la cuota y el atraso', () {
    final status = plan(
      [provision()],
      [deposit(372500, DateTime(2026, 9))],
    ).statuses.single;

    expect(status.saved, const Money.pesos(372500));
    expect(status.perCycle, const Money.pesos(37250));
    expect(status.behind, Money.zero);
    expect(status.light, TrafficLight.ok);
  });

  test('usar lo apartado al pagar lo descuenta', () {
    final status = plan(
      [provision()],
      [
        deposit(447000, DateTime(2026, 9)),
        withdrawal(447000, DateTime(2026, 10)),
      ],
    ).statuses.single;

    expect(status.saved, Money.zero);
  });

  test('vencido sin pagar: todo lo que falta es para este ciclo', () {
    final status = plan([provision(nextDue: DateTime(2026, 10))])
        .statuses
        .single;

    expect(status.isOverdue, isTrue);
    expect(status.pendingThisCycle, const Money.pesos(447000));
    expect(status.light, TrafficLight.critical);
  });

  test('completo: verde y sin pendiente', () {
    final status = plan(
      [provision()],
      [deposit(447000, DateTime(2026, 9))],
    ).statuses.single;

    expect(status.isReady, isTrue);
    expect(status.pendingThisCycle, Money.zero);
    expect(status.light, TrafficLight.ok);
  });

  test('pausados no cuentan; orden por fecha', () {
    final result = plan([
      provision(id: 'colegio', nextDue: DateTime(2027, 1, 15)),
      provision(),
      provision(id: 'pausado', isActive: false),
    ]);

    expect(result.statuses.map((s) => s.provision.id), ['soat', 'colegio']);
    expect(result.pausedCount, 1);
  });

  test('siguiente fecha respeta fin de mes', () {
    final p = provision(everyMonths: 2, nextDue: DateTime(2026, 12, 31));

    expect(p.followingDue, DateTime(2027, 2, 28));
  });

  test('divideUp nunca deja faltante', () {
    expect(const Money.pesos(100).divideUp(3), const Money.pesos(34));
    expect(const Money.pesos(99).divideUp(3), const Money.pesos(33));
  });
}
