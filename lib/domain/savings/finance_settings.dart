import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:meta/meta.dart';

/// Apariencia de la app: la del teléfono, clara u oscura.
enum Appearance { system, light, dark }

/// Cada cuánto "Tu CFO con IA" revisa tus finanzas (al abrir la app).
enum ReviewFrequency {
  daily(Duration(days: 1)),
  weekly(Duration(days: 7)),
  monthly(Duration(days: 30));

  new(this.interval);

  final Duration interval;

  /// `true` si ya pasó el intervalo desde [last] (o nunca se revisó).
  bool isDue({required DateTime? last, required DateTime now}) =>
      last == null || !now.isBefore(last.add(interval));
}

/// Preferencias configurables por el usuario.
@immutable
final class FinanceSettings {
  const new({
    this.savingsTargetRate = defaultSavingsTargetRate,
    this.thresholds = const TrafficLightThresholds(),
    this.smallExpenseThreshold = defaultSmallExpenseThreshold,
    this.payday = defaultPayday,
    this.dailyReminder = true,
    this.reminderHour = defaultReminderHour,
    this.reminderMinute = 0,
    this.smartNotifications = true,
    this.dependents = 0,
    this.soloProvider = false,
    this.kidsMonthlyBuffer = Money.zero,
    this.appearance = Appearance.system,
    this.aiEnabled = false,
    this.aiReviewFrequency = ReviewFrequency.weekly,
    this.monthlySalary = Money.zero,
  });

  /// Referencia (no obligación): 10% del ingreso.
  static const defaultSavingsTargetRate = Percentage.whole(10);
  static const defaultSmallExpenseThreshold = Money.pesos(20000);
  static const defaultPayday = 20;
  static const defaultReminderHour = 18;

  /// Horas de los avisos inteligentes (resumen de la mañana, mediodía,
  /// fijos de mañana y cierre de ciclo).
  static const morningBriefHour = 7;

  /// Frase del día para escribir (antes del resumen de la mañana).
  static const wisdomHour = 6;
  static const wisdomMinute = 30;
  static const middayNudgeHour = 13;
  static const fixedHeadsUpHour = 19;
  static const fixedDueHour = 8;
  static const cycleCloseHour = 19;

  /// Referencias del plan de fin de ciclo ("Tu CFO"). Son supuestos
  /// ilustrativos, no promesas de rentabilidad.
  static const referenceInflation = Percentage.whole(5);
  static const illustrativeAnnualReturn = Percentage.whole(8);
  static const illustrativeYears = 10;

  /// Deuda con tasa efectiva anual desde este valor se considera cara.
  static const expensiveDebtRate = Percentage.whole(20);

  /// Meses de gastos esenciales sugeridos para el fondo de emergencia:
  /// más si hay hijos a cargo y aún más si eres el único ingreso.
  static const suggestedEmergencyMonths = 3;
  static const emergencyMonthsWithDependents = 4;
  static const emergencyMonthsSoloWithDependents = 6;

  /// Apartado mensual sugerido para imprevistos, por cada hijo, como % del
  /// ingreso del ciclo.
  static const suggestedKidsBufferPerChild = Percentage.whole(5);

  /// Si sostienes solo el hogar con hijos, más del sobrante va al fondo de
  /// emergencia mientras no esté completo.
  static const emergencyShareSoloWithDependents = Percentage.whole(60);

  /// Reparto del sobrante: hasta este % al fondo de emergencia mientras no
  /// esté completo, y de lo que siga, este % a deuda cara.
  static const emergencyShare = Percentage.whole(50);
  static const expensiveDebtShare = Percentage.whole(50);

  /// De lo que se invierte, este % va a un fondo amplio; el resto a temas
  /// (IA, robótica…).
  static const broadFundShare = Percentage.whole(70);

  /// Días antes del fin de ciclo para el aviso de cierre (ahorrar/invertir
  /// lo que sobra).
  static const cycleCloseNoticeDays = 2;

  final Percentage savingsTargetRate;
  final TrafficLightThresholds thresholds;

  /// Gastos iguales o menores cuentan como "compra pequeña".
  final Money smallExpenseThreshold;

  /// Día del mes en que llega el sueldo: inicio de cada ciclo.
  final int payday;

  /// Recordatorio diario para registrar gastos e ingresos.
  final bool dailyReminder;

  /// Hora (0–23) del recordatorio.
  final int reminderHour;

  /// Minuto (0–59) del recordatorio.
  final int reminderMinute;

  /// Avisos útiles además del recordatorio: tope del día, mediodía, fijos
  /// de mañana, día de pago y cierre de ciclo.
  final bool smartNotifications;

  /// Hijos u otras personas a cargo.
  final int dependents;

  /// Sostienes el hogar sin otro ingreso ni ayuda (p. ej. sin aporte de la
  /// otra parte para los niños).
  final bool soloProvider;

  /// Apartado mensual para imprevistos de los niños (salud, colegio…). Se
  /// protege del tope diario.
  final Money kidsMonthlyBuffer;

  final Appearance appearance;

  /// El usuario aceptó enviar un resumen (sin descripciones) al proveedor
  /// de IA. Apagado por defecto.
  final bool aiEnabled;
  final ReviewFrequency aiReviewFrequency;

  /// Sueldo neto que llega cada mes (lo que cae en la cuenta). Cero = la
  /// app lo deduce de lo que registras en Salario. Base de "¿Puedo
  /// gastar…?" y de la proyección de los próximos meses.
  final Money monthlySalary;

  bool get hasSalary => monthlySalary.isPositive;

  bool get hasDependents => dependents > 0;

  /// Meses de gastos esenciales que debería cubrir el fondo de emergencia.
  int get emergencyMonths => !hasDependents
      ? suggestedEmergencyMonths
      : soloProvider
      ? emergencyMonthsSoloWithDependents
      : emergencyMonthsWithDependents;

  /// Parte del sobrante que va al fondo de emergencia mientras no esté
  /// completo.
  Percentage get emergencyShareOfLeftover => hasDependents && soloProvider
      ? emergencyShareSoloWithDependents
      : emergencyShare;

  FinanceSettings copyWith({
    Percentage? savingsTargetRate,
    TrafficLightThresholds? thresholds,
    Money? smallExpenseThreshold,
    int? payday,
    bool? dailyReminder,
    int? reminderHour,
    int? reminderMinute,
    bool? smartNotifications,
    int? dependents,
    bool? soloProvider,
    Money? kidsMonthlyBuffer,
    Appearance? appearance,
    bool? aiEnabled,
    ReviewFrequency? aiReviewFrequency,
    Money? monthlySalary,
  }) => FinanceSettings(
    savingsTargetRate: savingsTargetRate ?? this.savingsTargetRate,
    thresholds: thresholds ?? this.thresholds,
    smallExpenseThreshold: smallExpenseThreshold ?? this.smallExpenseThreshold,
    payday: payday ?? this.payday,
    dailyReminder: dailyReminder ?? this.dailyReminder,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    smartNotifications: smartNotifications ?? this.smartNotifications,
    dependents: dependents ?? this.dependents,
    soloProvider: soloProvider ?? this.soloProvider,
    kidsMonthlyBuffer: kidsMonthlyBuffer ?? this.kidsMonthlyBuffer,
    appearance: appearance ?? this.appearance,
    aiEnabled: aiEnabled ?? this.aiEnabled,
    aiReviewFrequency: aiReviewFrequency ?? this.aiReviewFrequency,
    monthlySalary: monthlySalary ?? this.monthlySalary,
  );

  @override
  bool operator ==(Object other) =>
      other is FinanceSettings &&
      other.savingsTargetRate == savingsTargetRate &&
      other.thresholds == thresholds &&
      other.smallExpenseThreshold == smallExpenseThreshold &&
      other.payday == payday &&
      other.dailyReminder == dailyReminder &&
      other.reminderHour == reminderHour &&
      other.reminderMinute == reminderMinute &&
      other.smartNotifications == smartNotifications &&
      other.dependents == dependents &&
      other.soloProvider == soloProvider &&
      other.kidsMonthlyBuffer == kidsMonthlyBuffer &&
      other.appearance == appearance &&
      other.aiEnabled == aiEnabled &&
      other.aiReviewFrequency == aiReviewFrequency &&
      other.monthlySalary == monthlySalary;

  @override
  int get hashCode => Object.hash(
    savingsTargetRate,
    thresholds,
    smallExpenseThreshold,
    payday,
    dailyReminder,
    reminderHour,
    reminderMinute,
    smartNotifications,
    dependents,
    soloProvider,
    kidsMonthlyBuffer,
    appearance,
    aiEnabled,
    aiReviewFrequency,
    monthlySalary,
  );
}
