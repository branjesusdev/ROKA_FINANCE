import 'dart:convert';

import 'package:finance_app/application/advisor/ai_ports.dart';
import 'package:finance_app/application/advisor/financial_snapshot.dart';
import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/advisor/ai_review.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';

/// Instrucciones fijas para el modelo. La IA interpreta y recomienda sobre
/// cálculos que ya hizo la app (deterministas); no hace las cuentas base.
abstract final class CfoPrompts {
  static const _rules = '''
Eres el CFO personal de una persona en Colombia que vive de su sueldo. Te paso
un resumen en JSON calculado por su app de finanzas (montos en pesos COP).

Reglas:
1. Usa SOLO los datos del JSON. No inventes cifras, rendimientos ni tasas.
   Si falta un dato para decidir, dilo y pídelo.
2. Nunca presentes estimaciones como garantías. Las acciones y fondos pueden
   bajar; la valorización de un bien no está garantizada.
3. Los ingresos extraordinarios (prima, cesantías, bonos, venta de activos)
   NO son dinero mensual: no los uses para sostener gastos recurrentes.
4. Orden de prioridades: (a) cubrir pagos fijos y liquidez del ciclo,
   (b) fondo de emergencia, (c) deudas caras (más de 20% efectivo anual),
   (d) ahorro para metas, (e) inversión diversificada, (f) emprender.
5. Sobre acciones individuales: habla de concentración, volatilidad, tamaño
   de la posición y diversificación. No digas "compra" ni "vende"; plantea
   alternativas y sus riesgos.
6. "alertasCalculadasPorReglas" ya son correctas: no las contradigas;
   explícalas y priorízalas.
7. Español de Colombia, simple, sin jerga contable. Sé concreto: montos,
   fechas y una acción que pueda hacer hoy.
8. Es información para decidir, no asesoría financiera profesional.''';

  static const review =
      '''
$_rules

Responde SOLO un objeto JSON con esta forma:
{
  "headline": "una frase: cómo va y lo más importante",
  "recommendations": [
    {
      "title": "acción en pocas palabras",
      "priority": "high" | "medium" | "low",
      "area": "liquidez | gastos | deudas | ahorro | inversión | activos | metas | emprender",
      "why": "motivo",
      "dataUsed": "qué datos del resumen usaste (con cifras)",
      "benefit": "beneficio esperado (estimado, no garantizado)",
      "risks": "riesgos",
      "assumptions": "supuestos",
      "action": "qué hacer hoy, concreto"
    }
  ],
  "missingData": ["dato que falta para analizar mejor"]
}
Entre 3 y 6 recomendaciones, de la más urgente a la menos.''';

  static const ask =
      '''
$_rules

Responde la pregunta en texto plano (sin markdown pesado), en máximo 250
palabras. Termina con "Qué haría hoy:" y una acción concreta.''';
}

/// Lee la respuesta JSON del modelo (tolera texto o ``` alrededor).
abstract final class AiReviewParser {
  static AiReview parse(
    String text, {
    required String id,
    required DateTime createdAt,
  }) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const AiAdvisorException(AiFailureReason.invalidResponse);
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(text.substring(start, end + 1));
    } on FormatException {
      throw const AiAdvisorException(AiFailureReason.invalidResponse);
    }
    if (decoded is! Map<String, Object?>) {
      throw const AiAdvisorException(AiFailureReason.invalidResponse);
    }
    String str(Map<String, Object?> m, String key) =>
        m[key]?.toString().trim() ?? '';
    final recommendations = [
      for (final r in decoded['recommendations'] as List? ?? const [])
        if (r is Map<String, Object?> && str(r, 'title').isNotEmpty)
          AiRecommendation(
            title: str(r, 'title'),
            priority:
                AdvicePriority.values.asNameMap()[str(r, 'priority')] ??
                AdvicePriority.medium,
            area: str(r, 'area'),
            why: str(r, 'why'),
            dataUsed: str(r, 'dataUsed'),
            benefit: str(r, 'benefit'),
            risks: str(r, 'risks'),
            assumptions: str(r, 'assumptions'),
            action: str(r, 'action'),
          ),
    ];
    final headline = str(decoded, 'headline');
    if (headline.isEmpty && recommendations.isEmpty) {
      throw const AiAdvisorException(AiFailureReason.invalidResponse);
    }
    return AiReview(
      id: id,
      createdAt: createdAt,
      headline: headline,
      recommendations: recommendations,
      missingData: [
        for (final m in decoded['missingData'] as List? ?? const [])
          if ('$m'.trim().isNotEmpty) '$m'.trim(),
      ],
    );
  }
}

/// Código de [RemoteFailure] cuando el usuario no ha activado la IA.
const aiDisabledCode = 'disabled';

final class _AiDisabled implements Exception {
  const new();
}

Future<Result<T>> _guardAi<T>(Future<T> Function() action) async {
  try {
    return await guardUseCase(action);
  } on AiAdvisorException catch (error) {
    return Err(RemoteFailure(error.reason.name));
  } on _AiDisabled {
    return const Err(RemoteFailure(aiDisabledCode));
  }
}

/// Pide a la IA una revisión completa y la guarda (la última se muestra en
/// Inicio y en Tu CFO). Requiere que el usuario haya activado la IA.
final class RunAiReview {
  const new({
    required this._advisor,
    required this._keys,
    required this._reviews,
    required this._settings,
    required this._clock,
    required this._ids,
  });

  final AiAdvisor _advisor;
  final AiKeyStore _keys;
  final AiReviewRepository _reviews;
  final SettingsRepository _settings;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<AiReview>> call(FinancialSnapshot snapshot) =>
      _guardAi(() async {
        if (!(await _settings.get()).aiEnabled) throw const _AiDisabled();
        final key = await _keys.read();
        if (key == null) {
          throw const AiAdvisorException(AiFailureReason.missingKey);
        }
        final text = await _advisor.complete(
          apiKey: key,
          system: CfoPrompts.review,
          prompt: snapshot.toJson(),
          json: true,
        );
        final review = AiReviewParser.parse(
          text,
          id: _ids.next(),
          createdAt: _clock.now(),
        );
        await _reviews.save(review);
        return review;
      });

  /// `true` si toca la revisión periódica (IA activa, con llave y ya pasó
  /// el intervalo elegido desde la última).
  Future<bool> isDue() async {
    try {
      final settings = await _settings.get();
      if (!settings.aiEnabled || await _keys.read() == null) return false;
      return settings.aiReviewFrequency.isDue(
        last: (await _reviews.latest())?.createdAt,
        now: _clock.now(),
      );
    } on Exception {
      return false;
    }
  }
}

/// Pregunta libre a "Tu CFO" con el resumen como contexto.
final class AskCfo {
  const new({
    required this._advisor,
    required this._keys,
    required this._settings,
  });

  final AiAdvisor _advisor;
  final AiKeyStore _keys;
  final SettingsRepository _settings;

  static const maxQuestionLength = 2500;

  Future<Result<String>> call({
    required FinancialSnapshot snapshot,
    required String question,
  }) => _guardAi(() async {
    if (!(await _settings.get()).aiEnabled) throw const _AiDisabled();
    final key = await _keys.read();
    if (key == null) {
      throw const AiAdvisorException(AiFailureReason.missingKey);
    }
    final clean = question.trim();
    final trimmed = clean.length > maxQuestionLength
        ? clean.substring(0, maxQuestionLength)
        : clean;
    return await _advisor.complete(
      apiKey: key,
      system: CfoPrompts.ask,
      prompt: 'Mis finanzas:\n${snapshot.toJson()}\n\nPregunta: $trimmed',
    );
  });
}

/// Guarda o borra la llave del proveedor de IA.
final class SaveAiKey {
  const new(this._keys);

  final AiKeyStore _keys;

  Future<Result<void>> call(String? key) => guardUseCase(() => _keys.save(key));
}

/// Activa/desactiva la IA y elige cada cuánto revisa.
final class UpdateAiSettings {
  const new(this._settings);

  final SettingsRepository _settings;

  Future<Result<void>> call({bool? enabled, ReviewFrequency? frequency}) =>
      guardUseCase(() async {
        final current = await _settings.get();
        await _settings.save(
          current.copyWith(aiEnabled: enabled, aiReviewFrequency: frequency),
        );
      });
}
