import 'dart:async';

import 'package:finance_app/application/voice/speech_input.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Dictado con el reconocedor de Android en modo `onDevice`: el audio no
/// sale del teléfono. Si falta el idioma sin conexión, falla en lugar de
/// usar la nube.
final class DeviceSpeechInput implements SpeechInput {
  new();

  static const _preferredLocale = 'es_CO';
  static const _spanishPrefix = 'es';
  static const _listenFor = Duration(seconds: 20);
  static const _pauseFor = Duration(seconds: 4);
  static const _languageErrors = {
    'error_language_not_supported',
    'error_language_unavailable',
    'error_server',
    'error_network',
    'error_server_disconnected',
  };
  static const _noMatchErrors = {'error_no_match', 'error_speech_timeout'};

  final _speech = SpeechToText();
  StreamController<SpeechChunk>? _controller;

  @override
  Stream<SpeechChunk> listen() {
    final controller = StreamController<SpeechChunk>();
    _controller = controller;
    unawaited(_start(controller));
    return controller.stream;
  }

  Future<void> _start(StreamController<SpeechChunk> controller) async {
    final available = await _speech.initialize(
      onError: _onError,
      onStatus: _onStatus,
    );
    if (!available) {
      await _fail(SpeechUnavailableReason.notAvailable);
      return;
    }

    final spanish = (await _speech.locales())
        .map((l) => l.localeId)
        .where((id) => id.startsWith(_spanishPrefix))
        .toList();
    if (spanish.isEmpty) {
      await _fail(SpeechUnavailableReason.offlineLanguageMissing);
      return;
    }
    await _speech.listen(
      onResult: (result) {
        if (controller.isClosed) return;
        controller.add(
          SpeechChunk(
            text: result.recognizedWords,
            isFinal: result.finalResult,
          ),
        );
        if (result.finalResult) unawaited(controller.close());
      },
      listenOptions: SpeechListenOptions(
        localeId: spanish.contains(_preferredLocale)
            ? _preferredLocale
            : spanish.first,
        onDevice: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        listenFor: _listenFor,
        pauseFor: _pauseFor,
      ),
    );
  }

  void _onError(SpeechRecognitionError error) {
    final reason = _languageErrors.contains(error.errorMsg)
        ? SpeechUnavailableReason.offlineLanguageMissing
        : _noMatchErrors.contains(error.errorMsg)
        ? SpeechUnavailableReason.noMatch
        : SpeechUnavailableReason.notAvailable;
    unawaited(_fail(reason));
  }

  // Si el reconocedor termina sin resultado final, cierra el stream.
  void _onStatus(String status) {
    final controller = _controller;
    if (status == SpeechToText.doneStatus &&
        controller != null &&
        !controller.isClosed) {
      unawaited(controller.close());
    }
  }

  Future<void> _fail(SpeechUnavailableReason reason) async {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    controller.addError(SpeechUnavailable(reason));
    await controller.close();
  }

  @override
  Future<void> stop() => _speech.stop();
}
