import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

/// Qué tan grande quedó lo que no se registró en un ciclo.
enum RecountLevel {
  /// Menos de [FinanceSettings.recountWarningGap]: normal, no afecta.
  fine,

  /// Entre los dos umbrales: vale la pena revisar.
  warning,

  /// Más de [FinanceSettings.recountAlertGap]: algo grande se escapó.
  alert;

  static RecountLevel of(Money difference) {
    final gap = difference.abs;
    if (gap > FinanceSettings.recountAlertGap) return alert;
    if (gap >= FinanceSettings.recountWarningGap) return warning;
    return fine;
  }
}

/// Reconteo de un ciclo: lo que de verdad quedó frente a lo registrado.
@immutable
final class CycleRecount {
  const new({required this.difference, required this.actualLeft});

  /// Compara lo que de verdad hay ([actual]) con lo registrado.
  factory measure({required Money registered, required Money actual}) =>
      CycleRecount(difference: actual - registered, actualLeft: actual);

  /// Negativo = gastos que se escaparon; positivo = dinero que no estaba
  /// registrado.
  final Money difference;

  /// Lo que de verdad quedó del ciclo (con la diferencia ya incluida).
  final Money actualLeft;

  /// Lo que la app tenía registrado antes del reconteo.
  Money get registeredLeft => actualLeft - difference;

  RecountLevel get level => RecountLevel.of(difference);
}
