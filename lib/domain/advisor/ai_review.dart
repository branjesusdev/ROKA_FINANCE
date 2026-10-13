import 'package:meta/meta.dart';

/// Qué tan pronto conviene actuar.
enum AdvicePriority { high, medium, low }

/// Recomendación de "Tu CFO con IA". Siempre explica de dónde sale: motivo,
/// datos usados, beneficio, riesgos, supuestos y una acción concreta.
@immutable
final class AiRecommendation {
  const new({
    required this.title,
    required this.priority,
    required this.why,
    required this.action,
    this.area = '',
    this.dataUsed = '',
    this.benefit = '',
    this.risks = '',
    this.assumptions = '',
  });

  final String title;
  final AdvicePriority priority;

  /// Gastos, deudas, ahorro, inversión, activos, liquidez…
  final String area;
  final String why;
  final String dataUsed;
  final String benefit;
  final String risks;
  final String assumptions;

  /// Lo que puedes hacer hoy.
  final String action;

  @override
  bool operator ==(Object other) =>
      other is AiRecommendation &&
      other.title == title &&
      other.priority == priority &&
      other.area == area &&
      other.why == why &&
      other.dataUsed == dataUsed &&
      other.benefit == benefit &&
      other.risks == risks &&
      other.assumptions == assumptions &&
      other.action == action;

  @override
  int get hashCode => Object.hash(
    title,
    priority,
    area,
    why,
    dataUsed,
    benefit,
    risks,
    assumptions,
    action,
  );
}

/// Una revisión completa: titular, recomendaciones ordenadas por prioridad
/// y los datos que faltan para analizar mejor.
@immutable
final class AiReview {
  const new({
    required this.id,
    required this.createdAt,
    required this.headline,
    required this.recommendations,
    this.missingData = const [],
  });

  final String id;
  final DateTime createdAt;
  final String headline;
  final List<AiRecommendation> recommendations;

  /// Datos que la IA pidió para dar un mejor análisis.
  final List<String> missingData;

  /// La más urgente (o `null` si no hubo recomendaciones).
  AiRecommendation? get top => recommendations.isEmpty
      ? null
      : recommendations.reduce(
          (a, b) => b.priority.index < a.priority.index ? b : a,
        );
}

/// Port: últimas revisiones guardadas en el teléfono.
abstract interface class AiReviewRepository {
  Future<void> save(AiReview review);

  Future<AiReview?> latest();

  Stream<AiReview?> watchLatest();
}
