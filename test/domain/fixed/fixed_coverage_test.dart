import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/fixed/fixed_coverage.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/fixed/fixed_payment_matcher.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const housing = 'seed-expense-housing';
  const services = 'seed-expense-services';
  final today = DateTime(2026, 10, 3, 10);
  final cycle = PayCycle.containing(today, payday: 20);

  FixedMovement fixed(
    String id,
    int pesos,
    int day, {
    String category = housing,
    bool variable = false,
  }) => FixedMovement(
    id: id,
    name: id,
    kind: TransactionKind.expense,
    amount: Money.pesos(pesos),
    categoryId: category,
    dayOfMonth: day,
    isVariable: variable,
  );

  FixedSchedule schedule(List<FixedMovement> movements) =>
      const FixedMovementScheduler().schedule(
        movements: movements,
        cycle: cycle,
        today: today,
      );

  group('reservas de los fijos', () {
    test('reparte el dinero del más cercano al más lejano', () {
      // Ejemplo: obligación de 600.000, hay 200.000 → faltan 400.000.
      final movements = [
        fixed('arriendo', 600000, 15),
        fixed('luz', 100000, 5),
      ];
      final plan = const FixedCoverageCalculator().calculate(
        schedule: schedule(movements),
        movements: movements,
        cycleTransactions: const [],
        available: const Money.pesos(300000),
      );

      final luz = plan.items.firstWhere((i) => i.movement.id == 'luz');
      final rent = plan.items.firstWhere((i) => i.movement.id == 'arriendo');
      expect(luz.state, ObligationState.covered);
      expect(rent.state, ObligationState.partial);
      expect(rent.reserved, const Money.pesos(200000));
      expect(rent.missing, const Money.pesos(400000));
      expect(plan.committed, const Money.pesos(700000));
      expect(plan.missing, const Money.pesos(400000));
    });

    test('sin dinero queda sin cubrir; lo pagado no cuenta como pendiente', () {
      final movements = [fixed('arriendo', 600000, 15), fixed('gym', 80000, 1)];
      final paid = Transaction(
        id: 't1',
        kind: TransactionKind.expense,
        amount: const Money.pesos(80000),
        categoryId: housing,
        date: DateTime(2026, 10),
        createdAt: DateTime(2026, 10),
        fixedMovementId: 'gym',
      );
      final plan = const FixedCoverageCalculator().calculate(
        schedule: schedule([movements.first]),
        movements: movements,
        cycleTransactions: [paid],
        available: Money.zero,
      );

      expect(plan.items.first.state, ObligationState.paid);
      expect(plan.items.last.state, ObligationState.uncovered);
      expect(plan.committed, const Money.pesos(600000));
    });

    test('una factura variable vencida aparece como vencida', () {
      final movements = [fixed('agua', 90000, 1, variable: true)];
      final plan = const FixedCoverageCalculator().calculate(
        schedule: schedule(movements),
        movements: movements,
        cycleTransactions: const [],
        available: const Money.pesos(1000000),
      );
      expect(plan.items.single.state, ObligationState.overdue);
    });
  });

  group('reconoce un pago fijo anotado a mano', () {
    final movements = [
      fixed('arriendo', 600000, 15),
      fixed('luz', 100000, 25, category: services, variable: true),
    ];

    test('misma categoría y valor parecido', () {
      final match = const FixedPaymentMatcher().match(
        schedule: schedule(movements),
        categoryId: housing,
        amount: const Money.pesos(610000),
      );
      expect(match?.movement.id, 'arriendo');
    });

    test('valor muy distinto u otra categoría: no es el fijo', () {
      const matcher = FixedPaymentMatcher();
      expect(
        matcher.match(
          schedule: schedule(movements),
          categoryId: housing,
          amount: const Money.pesos(50000),
        ),
        isNull,
      );
      expect(
        matcher.match(
          schedule: schedule(movements),
          categoryId: 'seed-expense-food',
          amount: const Money.pesos(600000),
        ),
        isNull,
      );
    });

    test('las facturas variables toleran más diferencia', () {
      final match = const FixedPaymentMatcher().match(
        schedule: schedule(movements),
        categoryId: services,
        amount: const Money.pesos(140000),
      );
      expect(match?.movement.id, 'luz');
    });
  });
}
