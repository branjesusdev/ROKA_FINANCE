import 'package:finance_app/domain/shared/money.dart';

/// Formato `$ 1.234.567` para textos generados fuera de la UI (avisos).
/// La UI usa `Formatters` (intl), que no puede importarse aquí.
abstract final class MoneyText {
  static const _groupSize = 3;

  static String format(Money money) {
    final pesos = (money.cents / Money.centsPerPeso).round();
    final digits = pesos.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % _groupSize == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '${pesos < 0 ? '-' : ''}\$ $buffer';
  }
}
