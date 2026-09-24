import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'assistant_message.dart';
import 'assistant_provider.dart';
import 'assistant_settings.dart';

class OpenAiCompatibleProvider implements AssistantProvider {
  OpenAiCompatibleProvider({required AssistantSettings settings, http.Client? client})
      : _settings = settings, _client = client ?? _createClient();
  final AssistantSettings _settings;
  final http.Client _client;

  static http.Client _createClient() {
    const ips = <String>['75.2.113.119', '99.83.136.103'];
    const host = 'integrate.api.nvidia.com';
    final c = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..connectionFactory = (uri, proxyHost, proxyPort) async {
        if (proxyHost != null || proxyPort != null || uri.host != host) {
          return Socket.startConnect(uri.host, uri.port);
        }
        try {
          final a = await InternetAddress.lookup(host, type: InternetAddressType.IPv4);
          if (a.isNotEmpty) return Socket.startConnect(a.first, uri.port);
        } catch (_) {}
        Object? lastError;
        for (final ip in ips) {
          try {
            return await Socket.startConnect(
              InternetAddress(ip, type: InternetAddressType.IPv4), uri.port);
          } catch (e) { lastError = e; }
        }
        throw SocketException(
          'No se pudo resolver ni alcanzar ' + host +
          (lastError == null ? '' : ': ' + lastError.toString()),
        );
      }
      ..findProxy = (uri) => 'DIRECT';
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
