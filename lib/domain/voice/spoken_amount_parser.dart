/// Monto encontrado en una frase y las palabras (índices) que lo forman.
final class SpokenAmount {
  const new({required this.pesos, required this.tokenIndexes});

  final int pesos;
  final Set<int> tokenIndexes;
}

/// Lee montos en pesos dictados en español colombiano, tal como los
/// devuelve el reconocedor de voz: "25000", "25.000", "$25,000", "25 mil",
/// "veinticinco mil", "1,5 millones", "dos millones trescientos mil",
/// "30 lucas", "15k".
///
/// Aritmética entera: los decimales ("1,5") se guardan como fracción.
final class SpokenAmountParser {
  const new();

  static const _thousand = 1000;
  static const _million = 1000000;

  static const _units = <String, int>{
    'un': 1, 'uno': 1, 'una': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, //
    'cinco': 5, 'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10,
    'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15,
    'dieciseis': 16, 'diecisiete': 17, 'dieciocho': 18, 'diecinueve': 19,
    'veinte': 20, 'veintiun': 21, 'veintiuno': 21, 'veintiuna': 21,
    'veintidos': 22, 'veintitres': 23, 'veinticuatro': 24,
    'veinticinco': 25, 'veintiseis': 26, 'veintisiete': 27,
    'veintiocho': 28, 'veintinueve': 29, 'treinta': 30, 'cuarenta': 40,
    'cincuenta': 50, 'sesenta': 60, 'setenta': 70, 'ochenta': 80,
    'noventa': 90, 'cien': 100, 'ciento': 100, 'doscientos': 200,
    'doscientas': 200, 'trescientos': 300, 'trescientas': 300,
    'cuatrocientos': 400, 'cuatrocientas': 400, 'quinientos': 500,
    'quinientas': 500, 'seiscientos': 600, 'seiscientas': 600,
    'setecientos': 700, 'setecientas': 700, 'ochocientos': 800,
    'ochocientas': 800, 'novecientos': 900, 'novecientas': 900,
  };

  static const _thousandWords = {'mil', 'lucas', 'luca', 'k'};
  static const _millionWords = {'millon', 'millones', 'palo', 'palos'};
  static const _currencyWords = {'pesos', 'peso', r'$'};

  static final _digits = RegExp(r'^\$?(\d+(?:[.,]\d+)*)(k?)$');
  static final _thousandsGrouping = RegExp(r'^\d{1,3}([.,]\d{3})+$');

  /// [tokens] ya normalizados (minúsculas, sin tildes). Si hay varios
  /// números ("20 mil en 2 almuerzos") se toma el mayor. `null` si no hay
  /// un monto positivo.
  SpokenAmount? parse(List<String> tokens) {
    SpokenAmount? best;
    var start = 0;
    while (start < tokens.length) {
      final amount = _startsNumber(tokens[start])
          ? _parseFrom(tokens, start)
          : null;
      if (amount == null) {
        start++;
        continue;
      }
      if (best == null || amount.pesos > best.pesos) best = amount;
      start = amount.tokenIndexes.reduce((a, b) => a > b ? a : b) + 1;
    }
    return best;
  }

  bool _startsNumber(String token) =>
      _digits.hasMatch(token) || _units.containsKey(token) || token == 'mil';

  SpokenAmount? _parseFrom(List<String> tokens, int start) {
    var total = 0;
    // Grupo actual como fracción numerador / denominador.
    var numerator = 0;
    var denominator = 1;
    var hasNumber = false;
    final used = <int>{};

    int current() => numerator ~/ denominator;

    for (var i = start; i < tokens.length; i++) {
      final token = tokens[i];
      final digitMatch = _digits.firstMatch(token);
      if (digitMatch != null) {
        if (hasNumber && numerator != 0) break; // Segundo número suelto.
        final (n, d) = _parseDigits(digitMatch.group(1)!);
        numerator = n;
        denominator = d;
        hasNumber = true;
        used.add(i);
        if (digitMatch.group(2) == 'k') {
          total += numerator * _thousand ~/ denominator;
          numerator = 0;
          denominator = 1;
        }
      } else if (_units[token] case final value?) {
        if (denominator != 1) break;
        numerator += value;
        hasNumber = true;
        used.add(i);
      } else if (_thousandWords.contains(token)) {
        final base = hasNumber && numerator != 0 ? numerator : denominator;
        total += base * _thousand ~/ denominator;
        numerator = 0;
        denominator = 1;
        hasNumber = true;
        used.add(i);
      } else if (_millionWords.contains(token) && hasNumber) {
        total =
            total * _million +
            (numerator == 0 ? _million : numerator * _million ~/ denominator);
        numerator = 0;
        denominator = 1;
        used.add(i);
      } else if (token == 'y' &&
          hasNumber &&
          i + 1 < tokens.length &&
          _units.containsKey(tokens[i + 1])) {
        used.add(i); // "treinta y cinco".
      } else if (_currencyWords.contains(token) && hasNumber) {
        used.add(i);
        break;
      } else {
        break;
      }
    }
    final pesos = total + current();
    if (!hasNumber || pesos <= 0) return null;
    return SpokenAmount(pesos: pesos, tokenIndexes: used);
  }

  /// "25.000" → 25000/1 · "1,5" → 15/10 · "2.300.000" → 2300000/1.
  (int, int) _parseDigits(String text) {
    if (_thousandsGrouping.hasMatch(text)) {
      return (int.parse(text.replaceAll(RegExp('[.,]'), '')), 1);
    }
    final parts = text.split(RegExp('[.,]'));
    if (parts.length != 2) {
      return (int.parse(parts.join()), 1);
    }
    var denominator = 1;
    for (var i = 0; i < parts[1].length; i++) {
      denominator *= 10;
    }
    return (int.parse(parts.join()), denominator);
  }
}
