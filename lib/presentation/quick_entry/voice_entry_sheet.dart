import 'dart:async';

import 'package:finance_app/application/voice/speech_input.dart';
import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/domain/voice/voice_entry_parser.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:finance_app/presentation/quick_entry/quick_entry_sheet.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dictado: "gasté 25 mil en almuerzo" → formulario prellenado para
/// confirmar. El reconocimiento ocurre en el teléfono.
Future<void> showVoiceEntrySheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const VoiceEntrySheet(),
    );

class VoiceEntrySheet extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<VoiceEntrySheet> createState() => _VoiceEntrySheetState();
}

enum _Phase { listening, failed }

class _VoiceEntrySheetState extends ConsumerState<VoiceEntrySheet> {
  late final SpeechInput _speech = ref.read(speechInputProvider);
  StreamSubscription<SpeechChunk>? _subscription;
  _Phase _phase = _Phase.listening;
  String _text = '';
  String? _error;

  static const _examples = [
    'Gasté 25 mil en almuerzo',
    'Pagué el arriendo 1.200.000',
    'Ayer 30 lucas de taxi',
    'Me pagaron el sueldo 4 millones',
  ];

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_speech.stop());
    super.dispose();
  }

  void _listen() {
    setState(() {
      _phase = _Phase.listening;
      _text = '';
      _error = null;
    });
    unawaited(_subscription?.cancel());
    _subscription = _speech.listen().listen(
      (chunk) {
        setState(() => _text = chunk.text);
        if (chunk.isFinal) _finish();
      },
      onError: (Object error) => _fail(
        error is SpeechUnavailable
            ? error.reason
            : SpeechUnavailableReason.notAvailable,
      ),
      onDone: () {
        if (mounted && _phase == _Phase.listening) _finish();
      },
    );
  }

  void _fail(SpeechUnavailableReason reason) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.failed;
      _error = switch (reason) {
        SpeechUnavailableReason.offlineLanguageMissing =>
          'Para dictar sin enviar tu voz a internet, descarga el español sin '
              'conexión: Ajustes del teléfono › Google › Voz › Reconocimiento '
              'sin conexión.',
        SpeechUnavailableReason.noMatch =>
          'No te entendí. Intenta de nuevo hablando cerca del teléfono.',
        SpeechUnavailableReason.notAvailable =>
          'No se pudo usar el micrófono. Revisa el permiso de micrófono de '
              'la app.',
      };
    });
  }

  void _finish() {
    if (!mounted || _phase != _Phase.listening) return;
    final text = _text.trim();
    if (text.isEmpty) return _fail(SpeechUnavailableReason.noMatch);

    final entry = const VoiceEntryParser().parse(
      text,
      categories: ref.read(categoriesProvider).value ?? const [],
    );
    final now = ref.read(clockProvider).now();
    final navigator = Navigator.of(context);
    final parent = navigator.context;
    navigator.pop();
    unawaited(
      showQuickEntrySheet(
        parent,
        draft: VoiceDraft(
          kind: entry.kind,
          pesos: entry.pesos,
          categoryId: entry.categoryId,
          description: entry.description,
          date: entry.daysAgo == 0
              ? null
              : DateTime(now.year, now.month, now.day - entry.daysAgo),
          heard: text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listening = _phase == _Phase.listening;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            listening ? 'Te escucho…' : 'No se pudo dictar',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Semantics(
            button: true,
            label: listening ? 'Terminar de dictar' : 'Intentar de nuevo',
            excludeSemantics: true,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: listening ? () => unawaited(_speech.stop()) : _listen,
              child: CircleAvatar(
                radius: 44,
                backgroundColor: listening
                    ? AppTheme.accent
                    : theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  listening ? Icons.mic : Icons.refresh,
                  size: 40,
                  color: AppTheme.onAccent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Text(_error!, textAlign: TextAlign.center)
          else if (_text.isNotEmpty)
            Text(
              _text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            )
          else ...[
            Text('Di algo como:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            for (final example in _examples)
              Text(
                '"$example"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
          if (!listening) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                final parent = navigator.context;
                navigator.pop();
                unawaited(showQuickEntrySheet(parent));
              },
              child: const Text('Escribirlo a mano'),
            ),
          ],
        ],
      ),
    );
  }
}
