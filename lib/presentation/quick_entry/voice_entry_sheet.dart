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
  String? _errorCode;
  String _diagnostics = '';
  SpeechUnavailableReason? _reason;

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

  void _listen({bool? online}) {
    setState(() {
      _phase = _Phase.listening;
      _text = '';
      _error = null;
      _errorCode = null;
      _reason = null;
    });
    unawaited(_subscription?.cancel());
    _subscription = _speech
        .listen(online: online)
        .listen(
          (chunk) {
            setState(() => _text = chunk.text);
            if (chunk.isFinal) _finish();
          },
          onError: (Object error) => _fail(
            error is SpeechUnavailable
                ? error.reason
                : SpeechUnavailableReason.notAvailable,
            code: error is SpeechUnavailable ? error.code : null,
          ),
          onDone: () {
            if (mounted && _phase == _Phase.listening) _finish();
          },
        );
  }

  void _fail(SpeechUnavailableReason reason, {String? code}) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.failed;
      _reason = reason;
      _errorCode = code;
      _diagnostics = '';
      _error = switch (reason) {
        SpeechUnavailableReason.offlineLanguageMissing =>
          'Tu teléfono no tiene español para dictar sin conexión. Toca '
              '"Dictar usando internet", o descarga Español en Ajustes del '
              'teléfono › Sistema › Idiomas › Voz › Reconocimiento en el '
              'dispositivo (o en la app Google › Ajustes › Voz › '
              'Reconocimiento sin conexión).',
        SpeechUnavailableReason.noMatch =>
          'No te entendí. Intenta de nuevo hablando cerca del teléfono.',
        SpeechUnavailableReason.notAvailable =>
          'El reconocedor de voz del teléfono no respondió. Toca "Dictar con '
              'Google" (usa el mismo dictado del teclado).',
      };
    });
    unawaited(_loadDiagnostics());
  }

  Future<void> _loadDiagnostics() async {
    final info = await _speech.diagnostics();
    if (mounted && _phase == _Phase.failed) {
      setState(() => _diagnostics = info);
    }
  }

  /// Respaldo: ventana de dictado de Google.
  Future<void> _dictateWithGoogle() async {
    unawaited(_subscription?.cancel());
    try {
      final text = await _speech.listenWithSystemDialog();
      if (!mounted) return;
      if (text == null || text.trim().isEmpty) {
        return _fail(SpeechUnavailableReason.noMatch);
      }
      setState(() {
        _phase = _Phase.listening;
        _text = text;
      });
      _finish();
    } on SpeechUnavailable catch (e) {
      _fail(e.reason, code: e.code);
    }
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
            Text(
              'Habla cuando quieras. Di algo como:',
              style: theme.textTheme.bodyMedium,
            ),
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
            if (_errorCode != null || _diagnostics.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                [
                  if (_errorCode != null) 'Código: $_errorCode',
                  if (_diagnostics.isNotEmpty) _diagnostics,
                ].join('\n'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_reason == SpeechUnavailableReason.offlineLanguageMissing &&
                !_speech.usesInternet) ...[
              FilledButton.icon(
                icon: const Icon(Icons.wifi),
                label: const Text('Dictar usando internet'),
                onPressed: () => _listen(online: true),
              ),
              const SizedBox(height: 4),
              Text(
                'Tu voz la procesa Google. Montos y descripciones no salen '
                'de la app; solo el audio de lo que digas.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.keyboard_voice_outlined),
              label: const Text('Dictar con Google'),
              onPressed: _dictateWithGoogle,
            ),
            const SizedBox(height: 8),
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
