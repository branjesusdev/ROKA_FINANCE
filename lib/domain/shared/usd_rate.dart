import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

/// Cuántos pesos cuesta un dólar. Convierte montos en dólares (en
/// centavos de dólar) a pesos, siempre en enteros.
@immutable
final class UsdRate {
  const new(this.pesosPerDollar);

  /// Centavos de dólar por dólar.
  static const centsPerDollar = 100;

  final Money pesosPerDollar;

  bool get isValid => pesosPerDollar.isPositive;

  /// [usdCents] centavos de dólar en pesos (redondeado al centavo).
  Money toPesos(int usdCents) => Money(
    (usdCents * pesosPerDollar.cents + centsPerDollar ~/ 2) ~/ centsPerDollar,
  );

  @override
  bool operator ==(Object other) =>
      other is UsdRate && other.pesosPerDollar == pesosPerDollar;

  @override
  int get hashCode => pesosPerDollar.hashCode;
}
