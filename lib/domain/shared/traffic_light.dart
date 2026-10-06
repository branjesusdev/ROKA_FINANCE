import 'package:finance_app/domain/shared/percentage.dart';
import 'package:meta/meta.dart';

/// Semáforo financiero. La UI siempre lo acompaña de icono, texto y %.
enum TrafficLight { ok, warning, critical }

/// Umbrales configurables para clasificar porcentajes de uso
/// (más alto = peor): presupuesto utilizado, gasto sobre ingreso.
@immutable
final class TrafficLightThresholds {
  const new({
    this.warningFrom = defaultWarningFrom,
    this.criticalAbove = defaultCriticalAbove,
  });

  static const defaultWarningFrom = Percentage.whole(80);
  static const Percentage defaultCriticalAbove = Percentage.hundred;

  /// Desde este uso se muestra advertencia (inclusive).
  final Percentage warningFrom;

  /// Por encima de este uso la situación es crítica (exclusivo).
  final Percentage criticalAbove;

  TrafficLight classifyUsage(Percentage usage) {
    if (usage > criticalAbove) return TrafficLight.critical;
    if (usage >= warningFrom) return TrafficLight.warning;
    return TrafficLight.ok;
  }

  @override
  bool operator ==(Object other) =>
      other is TrafficLightThresholds &&
      other.warningFrom == warningFrom &&
      other.criticalAbove == criticalAbove;

  @override
  int get hashCode => Object.hash(warningFrom, criticalAbove);
}
