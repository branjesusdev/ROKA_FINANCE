import 'package:finance_app/application/advisor/financial_alerts.dart';
import 'package:finance_app/application/common/money_text.dart';
import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/reminders/reminder_scheduler.dart';
import 'package:finance_app/domain/cycles/pay_cycle.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/fixed/fixed_movement_scheduler.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/wisdom/wealth_wisdom.dart';

/// Decide qué avisos programar a partir de la configuración y del ciclo.
///
/// Los avisos con montos se recalculan cada vez que abres la app; los que
/// se repiten a diario funcionan aunque no la abras.
final class ReminderPlanner {
  const new();

  static const dailyId = 1;
  static const middayId = 2;
  static const morningFirstId = 10;

  /// Frase del día (ids 20–26).
  static const wisdomFirstId = 20;

  static const writeItDown =
      'Escríbela a mano en tu cuaderno y léela en voz alta antes de salir.';
  static const fixedFirstId = 30;
  static const paydayId = 50;
  static const cycleCloseId = 51;
  static const alertsDigestId = 52;

  /// Pagos por confirmar: [billNoticesEach] avisos por pago, como máximo
  /// [maxBillNotices] en total (ids 60–95).
  static const billFirstId = 60;
  static const maxBillNotices = 36;

  /// Franjas en que se pregunta por un pago sin confirmar: mañana, tarde y
  /// noche.
  static const billCheckHours = [9, 15, 20];

  /// Avisos programados por pago (dos días de franjas): siguen llegando
  /// aunque no abras la app; al abrirla se reprograman.
  static const billNoticesEach = 6;

  /// Hora del resumen de alertas (la noche, para planear el día siguiente).
  static const alertsDigestHour = 20;

  /// Alertas mencionadas en el resumen.
  static const digestAlerts = 2;
  static const testId = 99;

  /// Días de resúmenes de la mañana programados por adelantado.
  static const morningDays = 7;

  /// Avisos de fijos (víspera + día de pago de cada uno), como máximo.
  static const maxFixedNotices = 20;

  /// Días hacia adelante en que se programan los avisos de fijos, aunque
  /// caigan en el próximo ciclo (el sueldo puede no haberse registrado).
  static const fixedLookaheadDays = 35;

  static const _paydayNoticeHour = 9;

  /// [fixedMovements]: todos los fijos, para avisar también los del próximo
  /// ciclo y el pago de hoy aunque ya se haya registrado solo. Sin ellos,
  /// usa los pendientes del ciclo de [summary].
  List<Reminder> plan({
    required FinanceSettings settings,
    required DateTime now,
    CycleSummary? summary,
    List<FinancialAlert> alerts = const [],
    List<Debt> debts = const [],
    List<FixedMovement>? fixedMovements,
  }) {
    final reminders = <Reminder>[];
    if (settings.dailyReminder) {
      reminders.add(
        Reminder(
          id: dailyId,
          at: _next(now, settings.reminderHour, settings.reminderMinute),
          title: '¿Cómo te fue hoy?',
          body:
              'Registra tus gastos e ingresos del día. Toma menos de un '
              'minuto.',
          channel: ReminderChannel.daily,
          repeatsDaily: true,
        ),
      );
    }
    if (!settings.smartNotifications) return reminders;

    reminders
      ..add(
        Reminder(
          id: middayId,
          at: _next(now, FinanceSettings.middayNudgeHour, 0),
          title: '¿Almuerzo, transporte, un antojo?',
          body: 'Anótalo ahora con el micrófono: toma 5 segundos.',
          repeatsDaily: true,
        ),
      )
      ..addAll(_wisdom(now))
      ..addAll(_mornings(now, summary))
      ..addAll(
        _fixedHeadsUp(
          now,
          fixedMovements == null
              ? summary?.upcomingFixed.upcoming ?? const []
              : _fixedDates(now, fixedMovements),
          debts,
          confirmHandled: summary != null,
        ),
      );
    if (summary != null) {
      reminders
        ..addAll(_cycleEdges(now, summary))
        ..addAll(_billsToConfirm(now, summary));
    }
    if (_alertsDigest(now, alerts) case final reminder?) {
      reminders.add(reminder);
    }
    return reminders;
  }

  /// Frase de un libro de dinero cada mañana, con qué hacer hoy y la
  /// invitación a escribirla (escribir la meta la vuelve concreta).
  Iterable<Reminder> _wisdom(DateTime now) sync* {
    final first = _next(
      now,
      FinanceSettings.wisdomHour,
      FinanceSettings.wisdomMinute,
    );
    for (var i = 0; i < morningDays; i++) {
      final at = DateTime(
        first.year,
        first.month,
        first.day + i,
        first.hour,
        first.minute,
      );
      final quote = WealthWisdom.quoteFor(at);
      yield Reminder(
        id: wisdomFirstId + i,
        at: at,
        title: 'Frase del día: escríbela',
        body: [
          '«${quote.text}»',
          '— ${quote.source}',
          if (quote.today case final today?) 'Hoy: $today',
          writeItDown,
        ].join('\n'),
      );
    }
  }

  Iterable<Reminder> _mornings(DateTime now, CycleSummary? summary) sync* {
    final first = _next(now, FinanceSettings.morningBriefHour, 0);
    for (var i = 0; i < morningDays; i++) {
      final at = DateTime(first.year, first.month, first.day + i, first.hour);
      final cap = i == 0 ? _capFor(at, now, summary) : null;
      yield Reminder(
        id: morningFirstId + i,
        at: at,
        title: cap == null
            ? 'Mira tu tope de hoy antes de gastar'
            : 'Hoy puedes gastar hasta ${MoneyText.format(cap)}',
        body:
            'Antes de un gasto que no tenías planeado, abre "¿Puedo '
            'gastar…?": te dice SÍ o NO con tu sueldo y tus pagos.',
      );
    }
  }

  /// Tope del día [at]. Si es mañana, reparte lo libre entre los días que
  /// quedarán.
  Money? _capFor(DateTime at, DateTime now, CycleSummary? summary) {
    final cap = summary?.dailyCap;
    if (summary == null || cap == null) return null;
    if (_sameDay(at, now)) return cap.cap;
    if (!summary.cycle.contains(at)) return null;
    final daysLeft = summary.cycle.daysLeft(at);
    if (daysLeft <= 0) return null;
    return (summary.leftAfterFixed - cap.reserved)
        .max(Money.zero)
        .divide(daysLeft);
  }

  /// Cada fijo avisa la víspera (para tener el dinero listo) y el mismo día
  /// de su pago (para hacerlo). Si [confirmHandled], los pagos por
  /// confirmar de hoy y mañana los pregunta [_billsToConfirm].
  Iterable<Reminder> _fixedHeadsUp(
    DateTime now,
    List<ScheduledFixed> dates,
    List<Debt> debts, {
    required bool confirmHandled,
  }) sync* {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    var id = fixedFirstId;
    final debtById = {for (final d in debts) d.id: d};
    for (final item in dates) {
      final date = item.date;
      final movement = item.movement;
      final amount = MoneyText.format(movement.amount);
      final debtNote = _debtNote(debtById[movement.debtId], movement.amount);
      final eve = DateTime(
        date.year,
        date.month,
        date.day - 1,
        FinanceSettings.fixedHeadsUpHour,
      );
      final dueDay = DateTime(
        date.year,
        date.month,
        date.day,
        FinanceSettings.fixedDueHour,
      );
      if (eve.isAfter(now) && id < fixedFirstId + maxFixedNotices) {
        yield Reminder(
          id: id++,
          at: eve,
          title: movement.isExpense
              ? 'Mañana: ${movement.name}'
              : 'Mañana llega: ${movement.name}',
          body: switch ((movement.isVariable, movement.isExpense)) {
            (true, true) =>
              'Calcula unos $amount (estimado). Cuando tengas la factura, '
                  'registra el valor real.',
            (true, false) => 'Estimado: $amount. Registra cuánto llegó.',
            (false, true) =>
              'Ten listos $amount. Ya están descontados de lo que te '
                  'queda.${debtNote ?? ''}',
            (false, false) => 'Se registrará solo: $amount.',
          },
        );
      }
      final asks = movement.needsConfirmation;
      if (dueDay.isAfter(now) &&
          movement.isExpense &&
          !(asks && confirmHandled && !date.isAfter(tomorrow)) &&
          id < fixedFirstId + maxFixedNotices) {
        yield Reminder(
          id: id++,
          at: dueDay,
          title: movement.isVariable
              ? '¿Cuánto llegó la factura de ${movement.name}?'
              : 'Hoy toca pagar: ${movement.name}',
          body: movement.isVariable
              ? 'Estimado $amount. Toca "Ya lo pagué" y escribe el valor '
                    'real, o pospónlo.'
              : asks
              ? '$amount. Hazlo hoy para evitar recargos y toca "Ya lo '
                    'pagué".${debtNote ?? ''}'
              : '$amount. Se descuenta solo (débito automático): ya quedó '
                    'registrado.${debtNote ?? ''}',
          actions: asks ? ReminderAction.values : const [],
          payload: asks ? movement.id : null,
        );
      }
    }
  }

  /// Fechas de los fijos activos de hoy a [fixedLookaheadDays] días, de la
  /// más cercana a la más lejana. El de hoy se incluye aunque ya se haya
  /// registrado solo (débito automático), salvo un pago ya confirmado.
  static List<ScheduledFixed> _fixedDates(
    DateTime now,
    List<FixedMovement> movements,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final until = DateTime(now.year, now.month, now.day + fixedLookaheadDays);
    final dates = <ScheduledFixed>[];
    for (final movement in movements.where((m) => m.isActive)) {
      final last = movement.lastPostedOn;
      // Tres meses cubren cualquier día del mes dentro de la ventana.
      for (var k = 0; k < 3; k++) {
        final date = PayCycle.paydayIn(
          now.year,
          now.month + k,
          movement.dayOfMonth,
        );
        if (date.isBefore(today) || date.isAfter(until)) continue;
        final posted = last != null && !last.isBefore(date);
        if (posted && (movement.needsConfirmation || !_sameDay(date, today))) {
          continue;
        }
        dates.add(ScheduledFixed(movement: movement, date: date));
      }
    }
    return dates..sort((a, b) => a.date.compareTo(b.date));
  }

  /// " Con esta cuota te quedan 18 cuotas y $8.200.000 de saldo."
  static String? _debtNote(Debt? debt, Money payment) {
    if (debt == null || !debt.currentBalance.isPositive) return null;
    final after = debt.afterInstallment(payment);
    final recorded = after.terms?.recordedRemainingInstallments;
    final left = MoneyText.format(after.currentBalance);
    if (!after.currentBalance.isPositive) {
      return ' ¡Con esta cuota terminas de pagar ${debt.name}!';
    }
    return recorded == null
        ? ' Después de esta cuota, ${debt.name} queda en $left.'
        : ' Después de esta cuota te quedan $recorded '
              '${recorded == 1 ? 'cuota' : 'cuotas'} de ${debt.name} y '
              '$left de saldo.';
  }

  Iterable<Reminder> _cycleEdges(DateTime now, CycleSummary summary) sync* {
    final end = summary.cycle.endExclusive;
    final close = DateTime(
      end.year,
      end.month,
      end.day - FinanceSettings.cycleCloseNoticeDays,
      FinanceSettings.cycleCloseHour,
    );
    if (close.isAfter(now)) {
      final left = summary.leftAfterFixed;
      yield Reminder(
        id: cycleCloseId,
        at: close,
        title: left.isPositive
            ? 'Te van sobrando ${MoneyText.format(left)} este ciclo'
            : 'El ciclo cierra en '
                  '${FinanceSettings.cycleCloseNoticeDays} días',
        body: left.isPositive
            ? 'No lo dejes quieto: abre "Tu CFO" y decide si va al fondo de '
                  'emergencia, a una deuda o a invertir.'
            : 'Revisa en qué se fue el dinero para ajustar el próximo ciclo.',
      );
    }
    final payday = DateTime(end.year, end.month, end.day, _paydayNoticeHour);
    if (payday.isAfter(now)) {
      yield Reminder(
        id: paydayId,
        at: payday,
        title: '¿Ya llegó tu sueldo?',
        body: summary.monthlyFixedExpenses.isPositive
            ? 'Regístralo y aparta de una vez '
                  '${MoneyText.format(summary.monthlyFixedExpenses)} para tus '
                  'fijos del mes. Si llega antes, regístralo ese día.'
            : 'Regístralo y arrancas un ciclo nuevo. Si llega antes, '
                  'regístralo ese día: lo que sobró pasa a ahorro.',
      );
    }
  }

  /// Una sola notificación al día con lo urgente (reglas, no IA). Se
  /// reprograma con cada cambio: no se repite ni se acumula.
  Reminder? _alertsDigest(DateTime now, List<FinancialAlert> alerts) {
    final urgent = alerts
        .where(
          (a) =>
              a.severity == AlertSeverity.critical ||
              a.severity == AlertSeverity.warning,
        )
        .toList();
    if (urgent.isEmpty) return null;
    final first = urgent.first;
    final more = urgent.length - 1;
    return Reminder(
      id: alertsDigestId,
      at: _next(now, alertsDigestHour, 0),
      title: first.title,
      body: [
        first.action,
        for (final a in urgent.skip(1).take(digestAlerts - 1)) '• ${a.title}',
        if (more >= digestAlerts) 'Y ${more - digestAlerts + 1} más en Tu CFO.',
      ].join('\n'),
    );
  }

  /// Pagos por confirmar (vencidos, de hoy o de mañana): avisos en la
  /// mañana, la tarde y la noche hasta que toques "Ya lo pagué", con
  /// botones "Ya lo pagué", "Mañana" y "En 2 días". Si lo pospusiste,
  /// empieza ese día.
  Iterable<Reminder> _billsToConfirm(DateTime now, CycleSummary summary) sync* {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final schedule = summary.upcomingFixed;
    final bills = [
      ...schedule.awaitingAmount,
      ...schedule.upcoming.where(
        (s) => s.movement.needsConfirmation && !s.date.isAfter(tomorrow),
      ),
    ].where((s) => s.movement.isExpense);
    var id = billFirstId;
    for (final bill in bills) {
      final movement = bill.movement;
      final until = movement.remindOn;
      var from = now;
      if (until != null && movement.isSnoozedOn(now)) from = until;
      if (bill.date.isAfter(from)) from = bill.date;
      final amount = MoneyText.format(movement.amount);
      for (final at in _slotsFrom(from).take(billNoticesEach)) {
        if (id >= billFirstId + maxBillNotices) return;
        final when = _sameDay(bill.date, at)
            ? 'Vence hoy'
            : 'Venció el ${bill.date.day}';
        yield Reminder(
          id: id++,
          at: at,
          title: movement.isVariable
              ? '¿Cuánto llegó la factura de ${movement.name}?'
              : '¿Ya pagaste ${movement.name}?',
          body: movement.isVariable
              ? '$when. Estimado $amount: toca "Ya lo pagué" y escribe el '
                    'valor real, o pospónlo.'
              : '$when: $amount. Toca "Ya lo pagué" o pospónlo. Te sigo '
                    'recordando hasta que lo confirmes.',
          actions: ReminderAction.values,
          payload: movement.id,
        );
      }
    }
  }

  /// Franjas de [billCheckHours] después de [from], día tras día.
  static Iterable<DateTime> _slotsFrom(DateTime from) sync* {
    for (var day = 0; ; day++) {
      for (final hour in billCheckHours) {
        final at = DateTime(from.year, from.month, from.day + day, hour);
        if (at.isAfter(from)) yield at;
      }
    }
  }

  static DateTime _next(DateTime now, int hour, int minute) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    return today.isAfter(now)
        ? today
        : DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
