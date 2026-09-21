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
    if (baseUrl.isEmpty || model.isEmpty) throw const FormatException('Faltan la URL base o el modelo del proveedor de IA.');

    final uri = Uri.tryParse(baseUrl + '/chat/completions');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) throw const FormatException('La URL base del proveedor no es válida.');

    final messages = history.where((m) => m.role != MessageRole.system).map((m) => {
      'role': m.role == MessageRole.user ? 'user' : 'assistant',
      'content': m.text,
    }).toList();
    if (messages.isEmpty || messages.last['role'] != 'user' || messages.last['content'] != text) {
      messages.add({'role': 'user', 'content': text});
    }

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (_settings.apiKey.trim().isNotEmpty) 'Authorization': 'Bearer ' + _settings.apiKey.trim(),
      },
      body: jsonEncode({'model': model, 'messages': messages}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('El proveedor de IA respondió con HTTP ' + response.statusCode.toString() + '.');

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('La respuesta de IA no tiene un formato válido.');
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) throw const FormatException('La respuesta de IA no contiene choices.');
    final message = choices.first['message'];
    if (message is! Map || message['content'] is! String) throw const FormatException('La respuesta de IA no contiene contenido.');
    final content = (message['content'] as String).trim();
    if (content.isEmpty) throw const FormatException('La IA devolvió una respuesta vacía.');

    return AssistantMessage(role: MessageRole.assistant, text: content, createdAt: DateTime.now());
  }
}