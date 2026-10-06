import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/voice/spoken_amount_parser.dart';

/// Borrador de movimiento a partir de una frase dictada. Todo es opcional:
/// el usuario revisa y confirma antes de guardar.
final class VoiceEntry {
  const new({
    required this.kind,
    this.pesos,
    this.categoryId,
    this.description,
    this.daysAgo = 0,
  });

  final TransactionKind kind;
  final int? pesos;
  final String? categoryId;
  final String? description;

  /// 1 = "ayer", 2 = "anteayer".
  final int daysAgo;
}

/// Interpreta frases como "gasté 25 mil en almuerzo", "pagué el arriendo
/// 1.200.000", "me pagaron el sueldo 4 millones" o "ayer 30 lucas de taxi".
final class VoiceEntryParser {
  const new();

  static const _incomeWords = {
    'ingreso', 'ingresos', 'recibi', 'pagaron', 'consignaron', 'gane', //
    'llego', 'entro', 'cobre', 'sueldo', 'salario', 'nomina', 'quincena',
  };

  /// Palabras clave por `iconKey`. Se prefiere la coincidencia más larga
  /// ("cuota alimentaria" antes que "cuota").
  static const keywordsByIcon = <String, List<String>>{
    'food': [
      'almuerzo', 'almuerzos', 'comida', 'mercado', 'restaurante', //
      'desayuno', 'cena', 'cafe', 'domicilio', 'rappi', 'pan', 'fruta',
      'frutas', 'supermercado', 'onces', 'tienda', 'hamburguesa', 'pizza',
    ],
    'housing': [
      'arriendo', 'alquiler', 'administracion', 'hipoteca', 'casa', //
    ],
    'transport': [
      'uber', 'taxi', 'bus', 'transmilenio', 'gasolina', 'peaje', //
      'parqueadero', 'didi', 'sitp', 'pasaje', 'pasajes', 'metro', 'moto',
    ],
    'education': [
      'colegio', 'universidad', 'curso', 'libros', 'matricula', //
      'pension', 'utiles', 'ruta',
    ],
    'health': [
      'medico', 'farmacia', 'drogueria', 'medicamento', 'medicamentos', //
      'eps', 'odontologo', 'cita', 'examenes', 'prepagada',
    ],
    'sports': [
      'entreno', 'entrenos', 'entrenamiento', 'gimnasio', 'gym', //
      'futbol', 'natacion', 'deporte', 'clases',
    ],
    'entertainment': [
      'cine', 'netflix', 'spotify', 'fiesta', 'salida', 'bar', //
      'cerveza', 'cervezas', 'concierto', 'paseo', 'disney',
    ],
    'debts': [
      'credito', 'cuota', 'prestamo', 'tarjeta', 'deuda', 'abono', //
    ],
    'services': [
      'luz', 'agua', 'gas', 'internet', 'celular', 'plan', 'energia', //
      'servicios', 'factura', 'recibo',
    ],
    'shopping': [
      'ropa', 'zapatos', 'compras', 'regalo', 'tenis', 'camisa', //
    ],
    'family': [
      'cuota alimentaria', 'hijos', 'hijo', 'hija', 'ninos', 'nino', //
      'mesada', 'panales', 'familia', 'mama', 'papa',
    ],
    'investments': [
      'inversion', 'cdt', 'acciones', 'ahorro', 'ahorre', //
    ],
    'salary': ['sueldo', 'salario', 'nomina', 'quincena', 'prima'],
    'additional_income': [
      'freelance', 'extra', 'bono', 'venta', 'vendi', 'honorarios', //
    ],
  };

  /// Palabras que no aportan a la descripción.
  static const _fillers = {
    'gaste', 'pague', 'compre', 'me', 'en', 'de', 'del', 'el', 'la', //
    'los', 'las', 'un', 'una', 'por', 'para', 'hoy', 'ayer', 'anteayer',
    'antier', 'fue', 'fueron', 'son', 'es', 'valor', 'gasto', 'y', 'con',
    'registra', 'registrar', 'anota', 'anotar', 'pesos', 'peso', 'ingreso',
    'recibi', 'pagaron', 'consignaron', 'gane', 'llego', 'entro', 'cobre',
  };

  VoiceEntry parse(String text, {required List<Category> categories}) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final original = <String>[];
    final tokens = <String>[];
    for (final word in words) {
      final token = normalize(word);
      if (token.isEmpty) continue;
      original.add(word);
      tokens.add(token);
    }
    final amount = const SpokenAmountParser().parse(tokens);
    final kind = tokens.any(_incomeWords.contains)
        ? TransactionKind.income
        : TransactionKind.expense;
    final daysAgo = tokens.contains('anteayer') || tokens.contains('antier')
        ? 2
        : tokens.contains('ayer')
        ? 1
        : 0;
    return VoiceEntry(
      kind: kind,
      pesos: amount?.pesos,
      categoryId: _category(tokens, categories, kind)?.id,
      description: _description(original, tokens, amount),
      daysAgo: daysAgo,
    );
  }

  Category? _category(
    List<String> tokens,
    List<Category> categories,
    TransactionKind kind,
  ) {
    final phrase = ' ${tokens.join(' ')} ';
    final wanted = kind == TransactionKind.income
        ? CategoryKind.income
        : CategoryKind.expense;
    Category? best;
    var bestLength = 0;
    for (final category in categories) {
      if (category.kind != wanted || category.isArchived) continue;
      final keywords = [
        normalize(category.name),
        ...?keywordsByIcon[category.iconKey],
      ];
      for (final keyword in keywords) {
        if (keyword.length > bestLength && phrase.contains(' $keyword ')) {
          best = category;
          bestLength = keyword.length;
        }
      }
    }
    return best;
  }

  String? _description(
    List<String> original,
    List<String> tokens,
    SpokenAmount? amount,
  ) {
    final kept = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      if (amount?.tokenIndexes.contains(i) ?? false) continue;
      // Quita relleno al inicio y al final, conserva el del medio
      // ("almuerzo con Juan").
      if (kept.isEmpty && _fillers.contains(tokens[i])) continue;
      kept.add(original[i].replaceAll(RegExp(r'[.,;:!?¿¡]+$'), ''));
    }
    while (kept.isNotEmpty && _fillers.contains(normalize(kept.last))) {
      kept.removeLast();
    }
    if (kept.isEmpty) return null;
    final text = kept.join(' ');
    return text[0].toUpperCase() + text.substring(1);
  }

  static const _accents = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n', //
  };

  /// Minúsculas, sin tildes y sin signos alrededor (conserva `$`, `.`, `,`
  /// dentro de números).
  static String normalize(String word) {
    final lower = word.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'^[^\w$]+'), '')
        .replaceAll(RegExp(r'[^\w]+$'), '');
  }
}
