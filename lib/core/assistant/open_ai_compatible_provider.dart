import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'assistant_message.dart';
import 'assistant_provider.dart';
import 'assistant_settings.dart';
import 'speech_translation_provider.dart';

class OpenAiCompatibleProvider implements AssistantProvider, SpeechTranslationProvider {
  OpenAiCompatibleProvider({required AssistantSettings settings, http.Client? client})
      : _settings = settings, _client = client ?? _createClient();
  final AssistantSettings _settings;
  final http.Client _client;

  static http.Client _createClient() {
    // Use Android/Dart's normal HTTPS stack so TLS SNI and the
    // certificate for integrate.api.nvidia.com are preserved.
    // Hard-coding the AWS load-balancer IPs here breaks HTTPS on
    // some Android networks because the connection loses the
    // hostname-based TLS routing.
    final c = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    return IOClient(c);
  }

  List<Map<String, String>> _messages(String text, List<AssistantMessage> history) {
    final raw = history
        .where((m) => m.role != MessageRole.system && m.text.trim().isNotEmpty)
        .map((m) => <String, String>{
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.text.trim(),
            }).toList();
    final out = <Map<String, String>>[];
    for (final m in raw) {
      if (out.isNotEmpty && out.last['role'] == m['role']) {
        if (m['role'] == 'user') {
          out[out.length - 1] = m;
        } else {
          out[out.length - 1]['content'] =
              out.last['content']! + '\n\n' + m['content']!;
        }
      } else {
        out.add(m);
      }
    }
    final current = text.trim();
    if (out.isEmpty || out.last['role'] != 'user') {
      out.add({'role': 'user', 'content': current});
    } else if (out.last['content'] != current) {
      out[out.length - 1] = {'role': 'user', 'content': current};
    }
    const maxMessages = 20;
    if (out.length > maxMessages) {
      out.removeRange(0, out.length - maxMessages);
      if (out.isNotEmpty && out.first['role'] == 'assistant') out.removeAt(0);
    }
    return out;
  }

  @override
  Future<AssistantMessage> sendMessage({
    required String text, required List<AssistantMessage> history,
  }) async {
    final base = _settings.apiBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    final model = _settings.model.trim();
    if (base.isEmpty || model.isEmpty) {
      throw const FormatException('Faltan la URL base o el modelo del proveedor de IA.');
    }
    final uri = Uri.tryParse(base + '/chat/completions');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('La URL base del proveedor no es válida.');
    }

    final messages = _messages(text, history);
    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'stream': false,
      'max_tokens': 2048,
      'temperature': 0.7,
      'chat_template_kwargs': {'enable_thinking': false},
    };

    http.Response response;
    try {
      response = await _post(uri, body);
    } on SocketException catch (e) {
      throw Exception(
        'No se pudo conectar con NVIDIA. Android no pudo resolver o alcanzar integrate.api.nvidia.com: ' +
        e.toString(),
      );
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar con el proveedor de IA: ' + e.toString());
    } on Exception catch (e) {
      throw Exception('No se pudo conectar con el proveedor de IA: ' + e.toString());
    }

    if (response.statusCode == 400) {
      final retry = await _post(uri, {
        'model': model,
        'messages': messages,
        'stream': false,
        'max_tokens': 1024,
        'chat_template_kwargs': {'enable_thinking': false},
      });
      if (retry.statusCode < 300 || retry.body.trim().isNotEmpty) response = retry;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final d = response.body.trim();
      throw Exception(
        'El proveedor de IA respondió con HTTP ' + response.statusCode.toString() + '.' +
        (d.isEmpty ? '' : ' Detalle: ' + (d.length > 1000 ? d.substring(0, 1000) : d)),
      );
    }
    if (response.body.trim().isEmpty) {
      throw const FormatException('El proveedor de IA devolvió una respuesta vacía.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('La respuesta de IA no tiene un formato válido.');
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) {
      throw const FormatException('La respuesta de IA no contiene choices.');
    }
    final message = choices.first['message'];
    if (message is! Map || message['content'] is! String) {
      throw const FormatException('La respuesta de IA no contiene contenido.');
    }
    final answer = (message['content'] as String).trim();
    if (answer.isEmpty) throw const FormatException('La IA devolvió una respuesta vacía.');
    return AssistantMessage(role: MessageRole.assistant, text: answer, createdAt: DateTime.now());
  }

  @override
  Future<String> translateForJapaneseSpeech(String spanishText) async {
    final text = spanishText.trim();
    if (text.isEmpty) return '';
    final base = _settings.apiBaseUrl.trim().replaceFirst(RegExp(r'/(Uri uri, Map<String, dynamic> body) => _client.post(
    uri,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_settings.apiKey.trim().isNotEmpty)
        'Authorization': 'Bearer ' + _settings.apiKey.trim(),
    },
    body: jsonEncode(body),
  ).timeout(const Duration(seconds: 60));
}
), '');
    final model = _settings.model.trim();
    final uri = Uri.tryParse(base + '/chat/completions');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty || model.isEmpty) {
      throw const FormatException('La configuración de NVIDIA no es válida para la voz japonesa.');
    }

    final response = await _post(uri, {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': 'Traduce al japonés natural el texto en español. Conserva exactamente el significado, nombres propios, números y tono. Devuelve SOLO el japonés, sin explicaciones, sin comillas y sin markdown.'
        },
        {'role': 'user', 'content': text},
      ],
      'stream': false,
      'max_tokens': 2048,
      'temperature': 0.2,
      'chat_template_kwargs': {'enable_thinking': false},
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo preparar la voz japonesa (HTTP ${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    final choices = decoded is Map ? decoded['choices'] : null;
    final message = choices is List && choices.isNotEmpty && choices.first is Map
        ? choices.first['message']
        : null;
    final answer = message is Map && message['content'] is String
        ? (message['content'] as String).trim()
        : '';
    if (answer.isEmpty) {
      throw const FormatException('La traducción japonesa llegó vacía.');
    }
    return answer;
  }

  Future<http.Response> _post(Uri uri, Map<String, dynamic> body) => _client.post(
    uri,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_settings.apiKey.trim().isNotEmpty)
        'Authorization': 'Bearer ' + _settings.apiKey.trim(),
    },
    body: jsonEncode(body),
  ).timeout(const Duration(seconds: 60));
}
