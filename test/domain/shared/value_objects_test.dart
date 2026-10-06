import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('trabaja en centavos exactos', () {
      expect(const Money.pesos(5000).cents, 500000);
      expect(
        Money.sum(const [Money.pesos(1), Money.pesos(2)]),
        const Money.pesos(3),
      );
    });

    test('redondea al centavo al multiplicar y dividir', () {
      expect(const Money(5).times(0.5), const Money(3));
      expect(const Money(10).divide(3), const Money(3));
    });

    test('aplica porcentajes', () {
      expect(
        const Money.pesos(7000000).applyPercentage(const Percentage.whole(10)),
        const Money.pesos(700000),
      );
    });
  });

  group('Percentage.ratio', () {
    test('calcula la proporción en puntos básicos', () {
      expect(
        Percentage.ratio(const Money(1), const Money(3)),
        const Percentage.basisPoints(3333),
      );
    });

    test('devuelve null si el total es cero', () {
      expect(Percentage.ratio(const Money(1), Money.zero), isNull);
    });
  });

  group('YearMonth', () {
    test('cruza años al avanzar y retroceder', () {
      expect(const YearMonth(2026, 12).next, const YearMonth(2027, 1));
      expect(const YearMonth(2026, 1).previous, const YearMonth(2025, 12));
      expect(
        const YearMonth(2026, 1).addMonths(-13),
        const YearMonth(2024, 12),
      );
    });

    test('cuenta meses entre períodos', () {
      expect(
        const YearMonth(2026, 10).monthsUntil(const YearMonth(2027, 4)),
        6,
      );
    });

    test('su rango incluye el primer día y excluye el mes siguiente', () {
      final range = const YearMonth(2026, 10).range;
      expect(range.contains(DateTime(2026, 10)), isTrue);
      expect(range.contains(DateTime(2026, 10, 31, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 11)), isFalse);
    });
  });

  group('TrafficLightThresholds.classifyUsage', () {
    const thresholds = TrafficLightThresholds();

    test('verde por debajo del 80%', () {
      expect(
        thresholds.classifyUsage(const Percentage.basisPoints(7999)),
        TrafficLight.ok,
      );
    });

    test('amarillo desde 80% hasta 100% inclusive', () {
      expect(
        thresholds.classifyUsage(const Percentage.whole(80)),
        TrafficLight.warning,
      );
      expect(
        thresholds.classifyUsage(Percentage.hundred),
        TrafficLight.warning,
      );
    });

    test('rojo al superar el 100%', () {
      expect(
        thresholds.classifyUsage(const Percentage.basisPoints(10001)),
        TrafficLight.critical,
      );
    });
  });
}
