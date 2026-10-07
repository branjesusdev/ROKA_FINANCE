import 'dart:async';

import 'package:finance_app/application/voice/speech_input.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Dictado con el reconocedor de Android en modo `onDevice`: el audio no
/// sale del teléfono. Si falta el idioma sin conexión, falla en lugar de
/// usar la nube.
///
/// Muchos teléfonos responden "no te entendí" (`error_no_match`) o cierran
/// la sesión apenas abre el micrófono, antes de que la persona hable. Por
/// eso, mientras no se haya oído ninguna palabra, se vuelve a escuchar en
/// silencio hasta [_waitForSpeech].
///
/// En teléfonos cuyo reconocedor por defecto no es Google (Honor, Huawei,
/// Xiaomi…) la lista de idiomas llega vacía aunque el español sin conexión
/// esté descargado: no se toma como error, se pide español directamente.
/// Si aun así falla, la UI ofrece [listenWithSystemDialog].
final class DeviceSpeechInput implements SpeechInput {
  new();

  static const _dictation = MethodChannel('finance_app/dictation');

  static const _preferredLocale = 'es_CO';
  static const _spanishPrefix = 'es';
  static const _listenFor = Duration(seconds: 30);
  static const _pauseFor = Duration(seconds: 3);
  static const _waitForSpeech = Duration(seconds: 12);
  static const _restartDelay = Duration(milliseconds: 250);
  static const _languageErrors = {
    'error_language_not_supported',
    'error_language_unavailable',
    'error_server',
    'error_network',
    'error_server_disconnected',
  };
  static const _noMatchErrors = {
    'error_no_match',
    'error_speech_timeout',
    // El reconocedor anterior aún no se liberó: también vale reintentar.
    'error_busy',
    'error_client',
  };

  final _speech = SpeechToText();
  bool _initialized = false;
  StreamController<SpeechChunk>? _controller;
  String? _localeId;
  String _heard = '';
  DateTime _startedAt = DateTime.now();
  bool _restarting = false;
  bool _stoppedByUser = false;

  @override
  Stream<SpeechChunk> listen() {
    final controller = StreamController<SpeechChunk>();
    _controller = controller;
    _heard = '';
    _lastCode = null;
    _stoppedByUser = false;
    _startedAt = DateTime.now();
    unawaited(_start(controller));
    return controller.stream;
  }

  Future<void> _start(StreamController<SpeechChunk> controller) async {
    if (!_initialized) {
      _initialized = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
    }
    if (!_initialized) {
      await _fail(SpeechUnavailableReason.notAvailable);
      return;
    }

    final spanish = (await _speech.locales())
        .map((l) => l.localeId)
        .where((id) => id.startsWith(_spanishPrefix))
        .toList();
    _localeId = spanish.isEmpty || spanish.contains(_preferredLocale)
        ? _preferredLocale
        : spanish.first;
    await _listenOnce(controller);
  }

  Future<void> _listenOnce(StreamController<SpeechChunk> controller) =>
      _speech.listen(
        onResult: (result) {
          if (controller.isClosed) return;
          final words = result.recognizedWords;
          if (words.trim().isNotEmpty) _heard = words;
          controller.add(SpeechChunk(text: words, isFinal: result.finalResult));
          if (result.finalResult && words.trim().isNotEmpty) {
            unawaited(controller.close());
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          onDevice: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          listenFor: _listenFor,
          pauseFor: _pauseFor,
        ),
      );

  /// `true` si se volvió a escuchar (aún nadie ha hablado).
  bool _retryIfSilent() {
    final controller = _controller;
    if (controller == null || controller.isClosed) return false;
    if (_stoppedByUser || _heard.trim().isNotEmpty) return false;
    if (DateTime.now().difference(_startedAt) > _waitForSpeech) return false;
    if (_restarting) return true;
    _restarting = true;
    unawaited(
      Future<void>.delayed(_restartDelay, () async {
        _restarting = false;
        if (controller.isClosed || _speech.isListening) return;
        await _listenOnce(controller);
      }),
    );
    return true;
  }

  void _onError(SpeechRecognitionError error) {
    _lastCode = error.errorMsg;
    if (_languageErrors.contains(error.errorMsg)) {
      unawaited(_fail(SpeechUnavailableReason.offlineLanguageMissing));
      return;
    }
    if (_noMatchErrors.contains(error.errorMsg)) {
      if (_retryIfSilent()) return;
      _finishOr(SpeechUnavailableReason.noMatch);
      return;
    }
    unawaited(_fail(SpeechUnavailableReason.notAvailable));
  }

  String? _lastCode;

  // El reconocedor terminó: si nadie habló aún, sigue escuchando; si ya hay
  // texto, lo entrega como final.
  void _onStatus(String status) {
    if (status != SpeechToText.doneStatus) return;
    if (_retryIfSilent()) return;
    _finishOr(SpeechUnavailableReason.noMatch);
  }

  /// Cierra con lo oído o, si no hubo nada, con [reason].
  void _finishOr(SpeechUnavailableReason reason) {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    if (_heard.trim().isNotEmpty) {
      controller.add(SpeechChunk(text: _heard, isFinal: true));
      unawaited(controller.close());
    } else if (_stoppedByUser) {
      unawaited(controller.close());
    } else {
      unawaited(_fail(reason));
    }
  }

  Future<void> _fail(SpeechUnavailableReason reason) async {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    controller.addError(SpeechUnavailable(reason, code: _lastCode));
    await controller.close();
  }

  @override
  Future<void> stop() async {
    _stoppedByUser = true;
    await _speech.stop();
  }

  @override
  Future<String?> listenWithSystemDialog() async {
    await _speech.cancel();
    try {
      return await _dictation.invokeMethod<String>('recognize', {
        'language': _preferredLocale.replaceAll('_', '-'),
        'prompt': 'Di tu gasto o ingreso',
      });
    } on PlatformException catch (e) {
      throw SpeechUnavailable(
        SpeechUnavailableReason.notAvailable,
        code: e.code,
      );
    } on MissingPluginException {
      throw const SpeechUnavailable(SpeechUnavailableReason.notAvailable);
    }
  }

  @override
  Future<String> diagnostics() async {
    try {
      return await _dictation.invokeMethod<String>('diagnose') ?? '';
    } on PlatformException catch (e) {
      return 'diagnose: ${e.code}';
    } on MissingPluginException {
      return '';
    }
  }
}
