import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/advisor/ai_review.dart';
import 'package:finance_app/presentation/cfo/ai_settings_screen.dart';
import 'package:finance_app/presentation/cfo/ask_cfo_sheet.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void openAiSettings(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => const AiSettingsScreen()));

/// Última revisión de la IA con cada recomendación explicada (motivo,
/// datos, beneficio, riesgos, supuestos y acción), y botones para revisar
/// ahora o preguntar.
class AiCfoCard extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AiCfoCard> createState() => _AiCfoCardState();
}

class _AiCfoCardState extends ConsumerState<AiCfoCard> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = ref.watch(settingsProvider).value?.aiEnabled ?? false;
    final hasKey = ref.watch(hasAiKeyProvider).value ?? false;
    final review = ref.watch(latestAiReviewProvider).value;
    final settingsButton = IconButton(
      tooltip: 'Ajustes de la IA',
      icon: const Icon(Icons.tune),
      onPressed: () => openAiSettings(context),
    );
    if (!enabled || !hasKey) {
      return SectionCard(
        title: 'Tu CFO con IA',
        trailing: settingsButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Un análisis de tus gastos, deudas, activos y metas con '
              'recomendaciones concretas, revisado cada día, semana o mes. '
              'Es opcional: tú decides qué se envía.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (hasKey) ...[
              Text(
                'Tu llave ya está guardada. Solo falta tu permiso para '
                'enviar el resumen a Groq.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: Text(hasKey ? 'Activar' : 'Configurar'),
              // Con llave, activar es dar el consentimiento aquí mismo.
              onPressed: () => hasKey
                  ? enableAiWithConsent(context, ref)
                  : openAiSettings(context),
            ),
          ],
        ),
      );
    }
    return SectionCard(
      title: 'Tu CFO con IA',
      trailing: settingsButton,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (review == null)
            Text(
              'Aún no hay revisiones. Pide la primera: tarda unos segundos.',
              style: theme.textTheme.bodyMedium,
            )
          else
            _ReviewView(review: review),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: _running
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_running ? 'Analizando…' : 'Revisar ahora'),
                  onPressed: _running ? null : _run,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Preguntar'),
                  onPressed: () => showAskCfoSheet(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _run() async {
    setState(() => _running = true);
    final snapshot = await ref.read(financialSnapshotProvider.future);
    final result = await ref.read(runAiReviewProvider).call(snapshot);
    if (!mounted) return;
    setState(() => _running = false);
    if (result case Err()) showResult(context, result);
  }
}

class _ReviewView extends StatelessWidget {
  const new({required this.review});

  final AiReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revisión del ${Formatters.longDate(review.createdAt)}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        if (review.headline.isNotEmpty)
          Text(
            review.headline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(height: 8),
        for (final r in review.recommendations) _RecommendationTile(r),
        if (review.missingData.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Para un mejor análisis, falta:',
            style: theme.textTheme.labelLarge,
          ),
          for (final missing in review.missingData)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.add_circle_outline, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(missing, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 8),
        Text(
          'Generado por IA con tus datos. Puede equivocarse: no es asesoría '
          'financiera y ningún rendimiento está garantizado.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const new(this.recommendation);

  final AiRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = recommendation;
    final sections = [
      ('Qué hacer', r.action, Icons.play_circle_outline),
      ('Por qué', r.why, Icons.help_outline),
      ('Datos usados', r.dataUsed, Icons.dataset_outlined),
      ('Beneficio esperado', r.benefit, Icons.trending_up),
      ('Riesgos', r.risks, Icons.warning_amber_outlined),
      ('Supuestos', r.assumptions, Icons.rule),
    ].where((s) => s.$2.isNotEmpty);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(r.title, style: theme.textTheme.titleSmall),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(
              icon: Icons.flag_outlined,
              label: [
                PriorityStyle.label(r.priority),
                if (r.area.isNotEmpty) r.area,
              ].join(' · '),
              color: PriorityStyle.color(r.priority, theme.colorScheme),
            ),
          ),
        ),
        children: [
          for (final (label, text, icon) in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$label: ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: text),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
