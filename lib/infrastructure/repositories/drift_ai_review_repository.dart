import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_app/domain/advisor/ai_review.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

/// Guarda las revisiones como JSON. Se conservan las últimas [keep].
final class DriftAiReviewRepository implements AiReviewRepository {
  const new(this._db);

  final AppDatabase _db;

  static const keep = 12;

  @override
  Future<void> save(AiReview review) => guardStorage(
    'aiReviews.save',
    () => _db.transaction(() async {
      await _db
          .into(_db.aiReviews)
          .insertOnConflictUpdate(
            AiReviewsCompanion.insert(
              id: review.id,
              createdAt: review.createdAt,
              content: jsonEncode(_toJson(review)),
            ),
          );
      final old =
          await (_db.select(_db.aiReviews)
                ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
                ..limit(-1, offset: keep))
              .get();
      if (old.isEmpty) return;
      await (_db.delete(
        _db.aiReviews,
      )..where((r) => r.id.isIn(old.map((o) => o.id)))).go();
    }),
  );

  @override
  Future<AiReview?> latest() => guardStorage(
    'aiReviews.latest',
    () async => _toDomain(await _latest().getSingleOrNull()),
  );

  @override
  Stream<AiReview?> watchLatest() => guardStorageStream(
    'aiReviews.watchLatest',
    _latest().watchSingleOrNull().map(_toDomain),
  );

  SimpleSelectStatement<$AiReviewsTable, AiReviewRow> _latest() =>
      _db.select(_db.aiReviews)
        ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
        ..limit(1);

  static AiReview? _toDomain(AiReviewRow? row) {
    if (row == null) return null;
    final json = jsonDecode(row.content) as Map<String, Object?>;
    return AiReview(
      id: row.id,
      createdAt: row.createdAt,
      headline: json['headline'] as String? ?? '',
      missingData: [
        for (final m in json['missingData'] as List? ?? const []) '$m',
      ],
      recommendations: [
        for (final r in json['recommendations'] as List? ?? const [])
          if (r is Map<String, Object?>)
            AiRecommendation(
              title: r['title'] as String? ?? '',
              priority:
                  AdvicePriority.values.asNameMap()[r['priority']] ??
                  AdvicePriority.medium,
              area: r['area'] as String? ?? '',
              why: r['why'] as String? ?? '',
              dataUsed: r['dataUsed'] as String? ?? '',
              benefit: r['benefit'] as String? ?? '',
              risks: r['risks'] as String? ?? '',
              assumptions: r['assumptions'] as String? ?? '',
              action: r['action'] as String? ?? '',
            ),
      ],
    );
  }

  static Map<String, Object?> _toJson(AiReview review) => {
    'headline': review.headline,
    'missingData': review.missingData,
    'recommendations': [
      for (final r in review.recommendations)
        {
          'title': r.title,
          'priority': r.priority.name,
          'area': r.area,
          'why': r.why,
          'dataUsed': r.dataUsed,
          'benefit': r.benefit,
          'risks': r.risks,
          'assumptions': r.assumptions,
          'action': r.action,
        },
    ],
  };
}
