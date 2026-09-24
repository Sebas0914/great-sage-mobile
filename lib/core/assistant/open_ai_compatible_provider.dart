import 'dart:convert';

import 'package:http/http.dart' as http;

import 'assistant_message.dart';
import 'assistant_provider.dart';
import 'assistant_settings.dart';

class OpenAiCompatibleProvider implements AssistantProvider {
  OpenAiCompatibleProvider({required AssistantSettings settings, http.Client? client})
      : _settings = settings,
        _client = client ?? http.Client();

  final AssistantSettings _settings;
  final http.Client _client;

  @override
  Future<AssistantMessage> sendMessage({
    required String text,
    required List<AssistantMessage> history,
  }) async {
    final baseUrl = _settings.apiBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    final model = _settings.model.trim();
    if (baseUrl.isEmpty || model.isEmpty) {
      throw const FormatException('Faltan la URL base o el modelo del proveedor de IA.');
    }

    final uri = Uri.tryParse(baseUrl + '/chat/completions');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('La URL base del proveedor no es válida.');
    }

    final messages = history
        .where((m) => m.role != MessageRole.system)
        .map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    if (messages.isEmpty ||
        messages.last['role'] != 'user' ||
        messages.last['content'] != text) {
      messages.add({'role': 'user', 'content': text});
    }

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (_settings.apiKey.trim().isNotEmpty)
                'Authorization': 'Bearer ${_settings.apiKey.trim()}',
            },
            body: jsonEncode({
              'model': model,
              'messages': messages,
              // NVIDIA's Nemotron 3.5 Lightning hosted endpoint defaults to
              // streaming. This client expects one JSON response, so explicitly
              // disable SSE streaming.
              'stream': false,
              // Keep the mobile client responsive and leave enough budget for
              // the visible answer.
              'max_tokens': 2048,
              'temperature': 0.7,
              // Nemotron 3.5 is a reasoning model. Disable internal thinking
              // here so message.content contains the final answer directly.
              'chat_template_kwargs': {'enable_thinking': false},
            }),
          )
          .timeout(const Duration(seconds: 60));
    } on Exception catch (error) {
      throw Exception('No se pudo conectar con el proveedor de IA: $error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final details = response.body.trim();
      final suffix = details.isEmpty
          ? ''
          : ' Detalle: ${details.length > 600 ? details.substring(0, 600) : details}';
      throw Exception(
        'El proveedor de IA respondió con HTTP ${response.statusCode}.\$suffix',
      );
    }

    if (response.body.trim().isEmpty) {
      throw const FormatException('El proveedor de IA devolvió una respuesta vacía.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('La respuesta de IA no tiene un formato válido.');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) {
      throw const FormatException('La respuesta de IA no contiene choices.');
    }

    final message = choices.first['message'];
    if (message is! Map || message['content'] is! String) {
      throw const FormatException('La respuesta de IA no contiene contenido.');
    }

    final content = (message['content'] as String).trim();
    if (content.isEmpty) {
      throw const FormatException('La IA devolvió una respuesta vacía.');
    }

    return AssistantMessage(
      role: MessageRole.assistant,
      text: content,
      createdAt: DateTime.now(),
    );
  }
}
