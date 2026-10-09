import 'package:finance_app/application/common/money_text.dart';
import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/application/reminders/reminder_scheduler.dart';
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
  static const fixedFirstId = 30;
  static const paydayId = 50;
  static const cycleCloseId = 51;
  static const testId = 99;

  /// Días de resúmenes de la mañana programados por adelantado.
  static const morningDays = 7;

  /// Avisos de fijos (víspera + día de pago de cada uno), como máximo.
  static const maxFixedNotices = 20;

  static const _paydayNoticeHour = 9;

  List<Reminder> plan({
    required FinanceSettings settings,
    required DateTime now,
    CycleSummary? summary,
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
      ..addAll(_mornings(now, summary));
    if (summary != null) {
      reminders
        ..addAll(_fixedHeadsUp(now, summary))
        ..addAll(_cycleEdges(now, summary));
    }
    return reminders;
  }

  Iterable<Reminder> _mornings(DateTime now, CycleSummary? summary) sync* {
    final first = _next(now, FinanceSettings.morningBriefHour, 0);
    for (var i = 0; i < morningDays; i++) {
      final at = DateTime(first.year, first.month, first.day + i, first.hour);
      final quote = WealthWisdom.quoteFor(at);
      final cap = i == 0 ? _capFor(at, now, summary) : null;
      yield Reminder(
        id: morningFirstId + i,
        at: at,
        title: cap == null
            ? 'Mira tu tope de hoy antes de gastar'
            : 'Hoy puedes gastar hasta ${MoneyText.format(cap)}',
        body: '«${quote.text}» — ${quote.author}',
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
  /// de su pago (para hacerlo).
  Iterable<Reminder> _fixedHeadsUp(DateTime now, CycleSummary summary) sync* {
    var id = fixedFirstId;
    for (final item in summary.upcomingFixed.upcoming) {
      final date = item.date;
      final movement = item.movement;
      final amount = MoneyText.format(movement.amount);
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
              'Ten listos $amount. Ya están descontados de lo que te queda.',
            (false, false) => 'Se registrará solo: $amount.',
          },
        );
      }
      if (dueDay.isAfter(now) &&
          movement.isExpense &&
          id < fixedFirstId + maxFixedNotices) {
        yield Reminder(
          id: id++,
          at: dueDay,
          title: movement.isVariable
              ? '¿Cuánto llegó la factura de ${movement.name}?'
              : 'Hoy toca pagar: ${movement.name}',
          body: movement.isVariable
              ? 'Abre la app y escribe el valor real en "Facturas por '
                    'confirmar" (estimado $amount).'
              : '$amount. Hazlo hoy para evitar recargos; ya quedó '
                    'registrado en tus movimientos.',
        );
      }
    }
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

  static DateTime _next(DateTime now, int hour, int minute) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    return today.isAfter(now)
        ? today
        : DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
