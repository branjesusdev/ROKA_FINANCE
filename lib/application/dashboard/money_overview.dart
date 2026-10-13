import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/fixed/fixed_coverage.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// "¿Cuánto tengo de verdad y cuánto puedo gastar?" separado en capas, para
/// no confundir el dinero que tienes con el dinero libre.
///
/// Son asignaciones dentro del ciclo: nada se mueve de una cuenta real.
final class MoneyOverview {
  const new({
    required this.available,
    required this.committed,
    required this.provisionsPending,
    required this.savingsPending,
    required this.expectedIncome,
    required this.extraordinaryIncome,
    required this.coverage,
    required this.daysLeft,
  });

  /// Dinero del ciclo hoy (ingresos − salidas + saldo cuadrado).
  final Money available;

  /// Gastos fijos que faltan en el ciclo.
  final Money committed;

  /// Lo que falta apartar este ciclo para pagos del año (SOAT, colegio…).
  final Money provisionsPending;

  /// Lo que falta del ahorro de referencia del ciclo.
  final Money savingsPending;

  /// Ingresos fijos que aún faltan en el ciclo (solo los configurados como
  /// fijos: son los únicos con suficiente certeza).
  final Money expectedIncome;

  /// Ingresos extraordinarios del ciclo (prima, cesantías…). Ya están en
  /// [available], pero no se repiten cada mes.
  final Money extraordinaryIncome;

  final CoveragePlan coverage;
  final int daysLeft;

  /// Reservado = fijos + apartados + ahorro pendiente.
  Money get reserved => committed + provisionsPending + savingsPending;

  /// Libre para gastar hasta el próximo sueldo sin tocar lo comprometido.
  /// Negativo = falta dinero.
  Money get free => available + expectedIncome - reserved;

  /// Lo que falta para cubrir todo (`null` si alcanza).
  Money? get shortfall => free.isNegative ? free.abs : null;

  /// Promedio diario libre (`null` si no hay días o no hay dinero libre).
  Money? get freePerDay =>
      daysLeft <= 0 || !free.isPositive ? null : free.divide(daysLeft);

  /// Sin ingresos ni saldo registrados en el ciclo: el cálculo es una
  /// estimación incompleta.
  bool get lacksData => available.isZero && committed.isZero;
}

final class MoneyOverviewBuilder {
  const new();

  MoneyOverview build({
    required CycleSummary summary,
    required List<Category> categories,
    required List<FixedMovement> fixedMovements,
    required List<Transaction> cycleTransactions,
  }) {
    final extraordinaryIds = {
      for (final c in categories)
        if (c.isExtraordinary) c.id,
    };
    final coverage = const FixedCoverageCalculator().calculate(
      schedule: summary.upcomingFixed,
      movements: fixedMovements,
      cycleTransactions: cycleTransactions,
      available: summary.left,
    );
    final savedThisCycle =
        summary.cashFlow.savingContributions -
        summary.provisionPlan.setAsideThisCycle;
    return MoneyOverview(
      available: summary.left,
      committed: coverage.committed,
      provisionsPending: summary.provisionPlan.pendingThisCycle,
      savingsPending: (summary.savingsTarget - savedThisCycle).max(Money.zero),
      expectedIncome: summary.upcomingFixed.upcomingIncome,
      extraordinaryIncome: Money.sum(
        cycleTransactions
            .where((t) => t.isIncome && extraordinaryIds.contains(t.categoryId))
            .map((t) => t.amount),
      ),
      coverage: coverage,
      daysLeft: summary.daysLeft,
    );
  }
}
