import 'package:finance_app/domain/cycles/daily_spending_cap.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DailySpendingCap? calculate({
    int available = 1000000,
    int daysLeft = 10,
    int spentToday = 0,
    int monthly = 0,
    int savings = 0,
  }) => const DailySpendingCapCalculator().calculate(
    available: Money.pesos(available),
    daysLeft: daysLeft,
    spentToday: Money.pesos(spentToday),
    monthlyReserve: Money.pesos(monthly),
    savingsReserve: Money.pesos(savings),
    thresholds: const TrafficLightThresholds(),
  );

  test('reparte lo libre entre los días que faltan, después de apartar '
      'mercado y ahorro', () {
    final cap = calculate(monthly: 300000, savings: 200000)!;

    expect(cap.cap, const Money.pesos(50000));
    expect(cap.reserved, const Money.pesos(500000));
    expect(cap.light, TrafficLight.ok);
  });

  test('lo gastado hoy no baja el tope del mismo día', () {
    // Ya descontado de lo disponible: 1.000.000 − 40.000.
    final cap = calculate(available: 960000, spentToday: 40000)!;

    expect(cap.cap, const Money.pesos(100000));
    expect(cap.remainingToday, const Money.pesos(60000));
    expect(cap.usage, const Percentage.whole(40));
  });

  test('pasarse del tope es crítico', () {
    final cap = calculate(available: 880000, spentToday: 120000)!;

    expect(cap.exceeded, isTrue);
    expect(cap.light, TrafficLight.critical);
  });

  test('sin margen el tope es cero; ciclo cerrado no tiene tope', () {
    expect(calculate(available: 100000, monthly: 300000)!.cap, Money.zero);
    expect(calculate(daysLeft: 0), isNull);
  });
}
