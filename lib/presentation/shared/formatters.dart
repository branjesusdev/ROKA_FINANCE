import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formato colombiano: `$ 5.000`, `24,5%`, `5 oct`.
///
/// intl no incluye datos `es_CO`; se usa `es` (miles con punto, decimales con
/// coma) y un patrón de moneda propio con el símbolo adelante.
abstract final class Formatters {
  static const locale = 'es';

  static final _money = NumberFormat.currency(
    locale: locale,
    customPattern: '¤ #,##0',
    symbol: r'$',
    decimalDigits: 0,
  );
  static final _percent = NumberFormat('#,##0.#', locale);
  static final _shortDate = DateFormat('d MMM', locale);
  static final _longDate = DateFormat("EEEE d 'de' MMMM", locale);
  static final _month = DateFormat("MMMM 'de' y", locale);
  static final _weekday = DateFormat('EEEE', locale);
  static final _pesos = NumberFormat.decimalPattern(locale);

  static String money(Money money) =>
      _money.format(money.cents / Money.centsPerPeso);

  static String percent(Percentage percentage) =>
      '${_percent.format(percentage.value)}%';

  static String shortDate(DateTime date) => _shortDate.format(date);

  static String longDate(DateTime date) => _capitalize(_longDate.format(date));

  static String month(YearMonth month) =>
      _capitalize(_month.format(DateTime(month.year, month.month)));

  static String pesos(int pesos) => _pesos.format(pesos);

  /// 1 = lunes … 7 = domingo, en plural ("los sábados").
  static String weekdayPlural(int weekday) {
    // 5 ene 2026 fue lunes.
    final name = _weekday.format(DateTime(2026, 1, 4 + weekday));
    return name.endsWith('s') ? name : '${name}s';
  }

  static String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

/// Campo de monto: solo dígitos, con separador de miles en vivo.
final class PesosInputFormatter extends TextInputFormatter {
  new();

  static const maxDigits = 12;

  /// Pesos enteros escritos, o `null` si está vacío.
  static int? parse(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : int.parse(digits);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return TextEditingValue.empty;
    if (digits.length > maxDigits) return oldValue;
    final formatted = Formatters.pesos(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
