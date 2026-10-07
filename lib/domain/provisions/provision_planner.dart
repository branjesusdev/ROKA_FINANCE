import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

/// Cómo va un apartado en el ciclo actual.
final class ProvisionStatus {
  const new({
    required this.provision,
    required this.saved,
    required this.savedBeforeCycle,
    required this.cyclesLeft,
    required this.perCycle,
    required this.setAsideThisCycle,
    required this.expectedSaved,
    required this.isOverdue,
    required this.daysUntilDue,
  });

  final Provision provision;

  /// Lo apartado hoy (aportes − lo usado al pagar).
  final Money saved;

  /// Lo apartado antes de empezar este ciclo.
  final Money savedBeforeCycle;

  /// Sueldos que llegan antes del pago, contando el de este ciclo.
  final int cyclesLeft;

  /// Lo que toca apartar en este ciclo para llegar a tiempo.
  final Money perCycle;

  /// Lo apartado en este ciclo.
  final Money setAsideThisCycle;

  /// Lo que ya debería estar apartado al empezar este ciclo, si se hubiera
  /// apartado parejo desde el pago anterior.
  final Money expectedSaved;

  /// La fecha de pago ya pasó y no se ha marcado como pagado.
  final bool isOverdue;

  /// Días desde hoy hasta el pago (negativo si ya pasó).
  final int daysUntilDue;

  Money get amount => provision.amount;

  Money get remaining => (amount - saved).max(Money.zero);

  /// Lo que falta apartar en este ciclo.
  Money get pendingThisCycle => isOverdue
      ? remaining
      : (perCycle - setAsideThisCycle).max(Money.zero).min(remaining);

  /// Lo que va atrasado frente a apartar parejo.
  Money get behind => (expectedSaved - savedBeforeCycle).max(Money.zero);

  /// Lo que se aparta en un ciclo normal (sin atrasos).
  Money get regularPerCycle => amount.divideUp(provision.everyMonths);

  bool get isReady => !remaining.isPositive;

  /// `null` si el monto es cero.
  Percentage? get progress => Percentage.ratio(saved, amount);

  /// Verde: al día. Amarillo: atrasado hasta un ciclo normal. Rojo:
  /// atrasado más que eso o vencido sin plata.
  TrafficLight get light {
    if (isReady) return TrafficLight.ok;
    if (isOverdue) return TrafficLight.critical;
    if (!behind.isPositive) return TrafficLight.ok;
    return behind <= regularPerCycle
        ? TrafficLight.warning
        : TrafficLight.critical;
  }
}

/// Todos los apartados del ciclo: cuánto apartar hoy y cuánto en el ciclo.
final class ProvisionPlan {
  const new({
    required this.statuses,
    required this.daysLeft,
    this.pausedCount = 0,
  });

  static const empty = ProvisionPlan(statuses: [], daysLeft: 0);

  /// Activos, del pago más cercano al más lejano.
  final List<ProvisionStatus> statuses;

  /// Días que faltan del ciclo, incluido hoy.
  final int daysLeft;

  final int pausedCount;

  bool get isEmpty => statuses.isEmpty;

  /// Lo que falta apartar en este ciclo. Se protege del tope diario.
  Money get pendingThisCycle =>
      Money.sum(statuses.map((s) => s.pendingThisCycle));

  Money get setAsideThisCycle =>
      Money.sum(statuses.map((s) => s.setAsideThisCycle));

  Money get saved => Money.sum(statuses.map((s) => s.saved));

  Money get behind => Money.sum(statuses.map((s) => s.behind));

  /// Lo que conviene apartar hoy para cumplir el ciclo (`null` si ya está).
  Money? get todaySetAside {
    final pending = pendingThisCycle;
    if (!pending.isPositive || daysLeft <= 0) return null;
    return pending.divideUp(daysLeft);
  }

  /// Costo promedio por mes de todos los apartados.
  Money get monthlyEquivalent => Money.sum(
    statuses.map((s) => s.amount.divideUp(s.provision.everyMonths)),
  );

  /// El peor semáforo (verde sin apartados).
  TrafficLight get light => statuses.fold(
    TrafficLight.ok,
    (worst, s) => s.light.index > worst.index ? s.light : worst,
  );

  ProvisionStatus? get next => statuses.firstOrNull;
}

/// Reparte cada pago entre los sueldos que llegan antes de su fecha.
final class ProvisionPlanner {
  const new();

  /// Aporte al apartado: gasto en la categoría Apartados.
  static bool isDeposit(Transaction t) =>
      t.provisionId != null &&
      t.isExpense &&
      t.categoryId == DefaultCategories.provisions.id;

  /// Uso del apartado al pagar: vuelve a la billetera como ajuste.
  static bool isWithdrawal(Transaction t) =>
      t.provisionId != null &&
      t.isIncome &&
      t.categoryId == DefaultCategories.balanceAdjustment.id;

  /// [linked]: movimientos con `provisionId` (de todas las fechas).
  ProvisionPlan plan({
    required List<Provision> provisions,
    required List<Transaction> linked,
    required PayCycle cycle,
    required DateTime today,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final active = provisions.where((p) => p.isActive).toList()
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
    return ProvisionPlan(
      statuses: [
        for (final provision in active) _status(provision, linked, cycle, day),
      ],
      daysLeft: cycle.daysLeft(day),
      pausedCount: provisions.length - active.length,
    );
  }

  ProvisionStatus _status(
    Provision provision,
    List<Transaction> linked,
    PayCycle cycle,
    DateTime today,
  ) {
    var saved = Money.zero;
    var savedBeforeCycle = Money.zero;
    var setAsideThisCycle = Money.zero;
    for (final t in linked.where((t) => t.provisionId == provision.id)) {
      final signed = isDeposit(t)
          ? t.amount
          : isWithdrawal(t)
          ? -t.amount
          : Money.zero;
      saved += signed;
      if (t.date.isBefore(cycle.start)) {
        savedBeforeCycle += signed;
      } else if (isDeposit(t) && cycle.contains(t.date)) {
        setAsideThisCycle += t.amount;
      }
    }

    final due = provision.nextDue;
    final cyclesLeft = _cyclesUntil(cycle, due);
    final remainingAtStart = (provision.amount - savedBeforeCycle).max(
      Money.zero,
    );
    final elapsed = (provision.everyMonths - cyclesLeft).clamp(
      0,
      provision.everyMonths,
    );
    return ProvisionStatus(
      provision: provision,
      saved: saved,
      savedBeforeCycle: savedBeforeCycle,
      cyclesLeft: cyclesLeft,
      perCycle: remainingAtStart.divideUp(cyclesLeft),
      setAsideThisCycle: setAsideThisCycle,
      expectedSaved: provision.amount.times(elapsed / provision.everyMonths),
      isOverdue: due.isBefore(today),
      // Con horario de verano un día puede durar 23 o 25 horas.
      daysUntilDue: (due.difference(today).inHours / Duration.hoursPerDay)
          .round(),
    );
  }

  /// Sueldos (inicios de ciclo) desde este ciclo hasta [due], mínimo 1.
  int _cyclesUntil(PayCycle cycle, DateTime due) {
    var count = 0;
    for (
      var start = cycle.start;
      !start.isAfter(due);
      start = PayCycle.containing(start, payday: cycle.payday).next.start
    ) {
      count++;
    }
    return count < 1 ? 1 : count;
  }
}
