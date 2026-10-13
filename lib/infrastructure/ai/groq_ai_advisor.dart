import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:finance_app/application/advisor/ai_ports.dart';

/// Modelo de lenguaje vía Groq (API compatible con OpenAI).
///
/// Qué sale del teléfono: solo el texto que arma la app (resumen agregado
/// que el usuario ve antes de activar la IA) y la llave que el usuario pegó.
/// Nunca se registra en logs.
final class GroqAiAdvisor implements AiAdvisor {
  new({HttpClient? client}) : _client = client ?? HttpClient();

  static const _host = 'api.groq.com';
  static const _path = '/openai/v1/chat/completions';
  static const model = 'openai/gpt-oss-120b';
  static const _timeout = Duration(seconds: 90);
  static const _maxTokens = 4096;
  static const _temperature = 0.3;

  final HttpClient _client;

  @override
  Future<String> complete({
    required String apiKey,
    required String system,
    required String prompt,
    bool json = false,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const AiAdvisorException(AiFailureReason.missingKey);
    }
    final body = jsonEncode({
      'model': model,
      'temperature': _temperature,
      'max_completion_tokens': _maxTokens,
      'reasoning_effort': 'medium',
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': prompt},
      ],
      if (json) 'response_format': {'type': 'json_object'},
    });
    final String responseText;
    final int status;
    try {
      final request = await _client
          .postUrl(Uri.https(_host, _path))
          .timeout(_timeout);
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer ${apiKey.trim()}')
        ..contentType = ContentType.json;
      request.add(utf8.encode(body));
      final response = await request.close().timeout(_timeout);
      status = response.statusCode;
      responseText = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);
    } on TimeoutException {
      throw const AiAdvisorException(AiFailureReason.network);
    } on IOException {
      throw const AiAdvisorException(AiFailureReason.network);
    }
    if (status == HttpStatus.unauthorized || status == HttpStatus.forbidden) {
      throw const AiAdvisorException(AiFailureReason.unauthorized);
    }
    if (status == HttpStatus.tooManyRequests) {
      throw const AiAdvisorException(AiFailureReason.rateLimited);
    }
    if (status != HttpStatus.ok) {
      throw const AiAdvisorException(AiFailureReason.network);
    }
    try {
      final decoded = jsonDecode(responseText) as Map<String, Object?>;
      final choices = decoded['choices']! as List;
      final message =
          (choices.first as Map<String, Object?>)['message']!
              as Map<String, Object?>;
      final content = message['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw const AiAdvisorException(AiFailureReason.invalidResponse);
      }
      return content;
    } on AiAdvisorException {
      rethrow;
      // Respuesta con otra forma (no es un error de programación).
      // ignore: avoid_catching_errors
    } on TypeError {
      throw const AiAdvisorException(AiFailureReason.invalidResponse);
    } on FormatException {
      throw const AiAdvisorException(AiFailureReason.invalidResponse);
    }
  }
}
