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
///
/// El reconocedor sin conexión de Google no trae paquete de español de
/// Colombia (`error_language_not_supported`): se prueban en orden otras
/// variantes latinas que sí suele tener (EE. UU., Latinoamérica, México,
/// España) y se recuerda la que funcionó.
final class DeviceSpeechInput implements SpeechInput {
  new();

  static const _dictation = MethodChannel('finance_app/dictation');

  static const _preferredLocale = 'es_CO';
  static const _spanishPrefix = 'es';

  /// Variantes a probar si el teléfono no tiene [_preferredLocale] sin
  /// conexión, de más a menos parecida al español de Colombia.
  static const _fallbackLocales = ['es_US', 'es_419', 'es_MX', 'es_ES'];
  static const _dialogFallback = 'es_US';
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
  List<String> _locales = const [_preferredLocale, ..._fallbackLocales];

  /// Variante en uso. Se conserva entre dictados: la que funcionó.
  int _localeIndex = 0;
  String get _localeId => _locales[_localeIndex];

  /// Ninguna variante de español funcionó sin conexión.
  bool _noOfflineSpanish = false;
  String _heard = '';
  DateTime _startedAt = DateTime.now();
  bool _restarting = false;
  bool _stoppedByUser = false;

  bool _online = false;

  @override
  bool get usesInternet => _online;

  @override
  Stream<SpeechChunk> listen({bool? online}) {
    if (online != null) _online = online;
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

    if (_localeIndex == 0) {
      final reported = (await _speech.locales())
          .map((l) => l.localeId)
          .where((id) => id.startsWith(_spanishPrefix))
          .toList();
      _locales = orderLocales(reported);
    }
    await _listenOnce(controller);
  }

  Future<void> _listenOnce(StreamController<SpeechChunk> controller) =>
      _speech.listen(
        onResult: (result) {
          if (controller.isClosed) return;
          final words = result.recognizedWords;
          if (words.trim().isNotEmpty) {
            _heard = words;
            _noOfflineSpanish = false;
          }
          controller.add(SpeechChunk(text: words, isFinal: result.finalResult));
          if (result.finalResult && words.trim().isNotEmpty) {
            unawaited(controller.close());
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: _online ? _preferredLocale : _localeId,
          // Con internet, el reconocedor de Google sí entiende es-CO.
          onDevice: !_online,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          listenFor: _listenFor,
          pauseFor: _pauseFor,
        ),
      );

  /// Orden de prueba: Colombia, luego las variantes conocidas, luego otras
  /// que reporte el teléfono. Sin lista (reconocedor que no la expone) se
  /// usan las conocidas.
  static List<String> orderLocales(List<String> reported) {
    final known = [_preferredLocale, ..._fallbackLocales];
    return {
      ...known.where((id) => reported.isEmpty || reported.contains(id)),
      ...reported,
      // Aunque no se reporten, se prueban: varios reconocedores mienten.
      ...known,
    }.toList();
  }

  /// `true` si pasa a la siguiente variante de español (aún nadie habló).
  bool _tryNextLocale() {
    final controller = _controller;
    if (controller == null || controller.isClosed) return false;
    if (_stoppedByUser || _heard.trim().isNotEmpty) return false;
    if (_localeIndex + 1 >= _locales.length) {
      _localeIndex = 0;
      _noOfflineSpanish = true;
      return false;
    }
    _localeIndex++;
    _startedAt = DateTime.now();
    _restart(controller);
    return true;
  }

  /// `true` si se volvió a escuchar (aún nadie ha hablado).
  bool _retryIfSilent() {
    final controller = _controller;
    if (controller == null || controller.isClosed) return false;
    if (_stoppedByUser || _heard.trim().isNotEmpty) return false;
    if (DateTime.now().difference(_startedAt) > _waitForSpeech) return false;
    _restart(controller);
    return true;
  }

  void _restart(StreamController<SpeechChunk> controller) {
    if (_restarting) return;
    _restarting = true;
    unawaited(
      Future<void>.delayed(_restartDelay, () async {
        _restarting = false;
        if (controller.isClosed || _speech.isListening) return;
        await _listenOnce(controller);
      }),
    );
  }

  void _onError(SpeechRecognitionError error) {
    _lastCode = error.errorMsg;
    if (_languageErrors.contains(error.errorMsg)) {
      if (!_online && _tryNextLocale()) return;
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
        // La variante que funcionó sin conexión. Si ninguna lo hizo, pedir
        // "solo sin conexión" hace que Google responda "la búsqueda por voz
        // no está disponible": se deja que Google decida.
        'language': (_noOfflineSpanish ? _dialogFallback : _localeId)
            .replaceAll('_', '-'),
        'preferOffline': !_noOfflineSpanish,
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
