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
  static final _monthShort = DateFormat('MMM y', locale);
  static final _monthAbbr = DateFormat('MMM', locale);
  static final _weekday = DateFormat('EEEE', locale);
  static final _weekdayShort = DateFormat('EEE', locale);
  static final _pesos = NumberFormat.decimalPattern(locale);
  static final _usd = NumberFormat('#,##0.00', locale);

  static String money(Money money) =>
      _money.format(money.cents / Money.centsPerPeso);

  static String percent(Percentage percentage) =>
      '${_percent.format(percentage.value)}%';

  static String shortDate(DateTime date) => _shortDate.format(date);

  /// "nov", "dic"…
  static String monthAbbr(DateTime date) => _monthAbbr.format(date);

  static String longDate(DateTime date) => _capitalize(_longDate.format(date));

  static String month(YearMonth month) =>
      _capitalize(_month.format(DateTime(month.year, month.month)));

  /// "dic 2026".
  static String monthShort(YearMonth month) =>
      _monthShort.format(DateTime(month.year, month.month));

  static String pesos(int pesos) => _pesos.format(pesos);

  /// Centavos de dólar como `US$ 253,70`.
  static String usd(int cents) => 'US\$ ${usdNumber(cents)}';

  /// Centavos de dólar como `253,70` (para prellenar campos).
  static String usdNumber(int cents) => _usd.format(cents / 100);

  /// 1 = lunes … 7 = domingo, en plural ("los sábados").
  static String weekdayPlural(int weekday) {
    // 5 ene 2026 fue lunes.
    final name = _weekday.format(DateTime(2026, 1, 4 + weekday));
    return name.endsWith('s') ? name : '${name}s';
  }

  /// 1 = lunes … 7 = domingo, abreviado ("Lun").
  static String weekdayShort(int weekday) => _capitalize(
    _weekdayShort.format(DateTime(2026, 1, 4 + weekday)).replaceAll('.', ''),
  );

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

/// Lee montos en dólares con decimales: "253.70", "253,70", "1.253,70" o
/// "1,253.70". El último separador con 1 o 2 cifras después es el decimal.
abstract final class UsdInput {
  static const _centsDigits = 2;

  /// Centavos de dólar, o `null` si está vacío o no es número.
  static int? parse(String text) {
    final clean = text.replaceAll(RegExp('[^0-9.,]'), '');
    if (clean.isEmpty) return null;
    final lastSeparator = clean.lastIndexOf(RegExp('[.,]'));
    var whole = clean;
    var decimals = '';
    if (lastSeparator >= 0) {
      final after = clean.substring(lastSeparator + 1);
      if (after.isNotEmpty && after.length <= _centsDigits) {
        whole = clean.substring(0, lastSeparator);
        decimals = after;
      }
    }
    final digits = whole.replaceAll(RegExp('[.,]'), '');
    if (digits.isEmpty && decimals.isEmpty) return null;
    final dollars = int.tryParse(digits.isEmpty ? '0' : digits);
    if (dollars == null) return null;
    final cents = int.parse(decimals.padRight(_centsDigits, '0'));
    return dollars * 100 + cents;
  }
}
