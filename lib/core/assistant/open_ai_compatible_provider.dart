import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'assistant_message.dart';
import 'assistant_provider.dart';
import 'assistant_settings.dart';
import '../automation/automation_provider.dart';
import 'speech_translation_provider.dart';

class OpenAiCompatibleProvider implements AssistantProvider, SpeechTranslationProvider, AutomationProvider {
  OpenAiCompatibleProvider({required AssistantSettings settings, http.Client? client}) : _settings = settings, _client = client ?? _createClient();
  final AssistantSettings _settings;
  final http.Client _client;

  static http.Client _createClient() {
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    return IOClient(c);
  }

  List<Map<String, String>> _messages(String text, List<AssistantMessage> history) {
    final raw = history.where((m) => m.role != MessageRole.system && m.text.trim().isNotEmpty).map((m) => <String, String>{'role': m.role == MessageRole.user ? 'user' : 'assistant', 'content': m.text.trim()}).toList();
    final out = <Map<String, String>>[];
    for (final m in raw) {
      if (out.isNotEmpty && out.last['role'] == m['role']) {
        if (m['role'] == 'user') out[out.length - 1] = m; else out[out.length - 1]['content'] = out.last['content']! + '\n\n' + m['content']!;
      } else { out.add(m); }
    }
    final current = text.trim();
    if (out.isEmpty || out.last['role'] != 'user') out.add({'role': 'user', 'content': current});
    else if (out.last['content'] != current) out[out.length - 1] = {'role': 'user', 'content': current};
    const maxMessages = 20;
    if (out.length > maxMessages) { out.removeRange(0, out.length - maxMessages); if (out.isNotEmpty && out.first['role'] == 'assistant') out.removeAt(0); }
    return out;
  }

  @override Future<AssistantMessage> sendMessage({required String text, required List<AssistantMessage> history}) async {
    final answer = _extractContent(await _request(_messages(text, history), maxTokens: 2048, temperature: 0.7));
    if (answer.isEmpty) throw const FormatException('La IA devolvió una respuesta vacía.');
    return AssistantMessage(role: MessageRole.assistant, text: answer, createdAt: DateTime.now());
  }

  @override Future<String> translateForJapaneseSpeech(String spanishText) async {
    final text = spanishText.trim(); if (text.isEmpty) return '';
    final answer = _extractContent(await _request([{'role':'system','content':'Traduce al japonés natural el texto en español. Conserva exactamente el significado, nombres propios, números y tono. Devuelve SOLO el japonés, sin explicaciones, sin comillas y sin markdown.'},{'role':'user','content':text}], maxTokens: 2048, temperature: 0.2));
    if (answer.isEmpty) throw const FormatException('La traducción japonesa llegó vacía.'); return answer;
  }

  @override Future<String> planAutomation(String command) async {
    final text = command.trim(); if (text.isEmpty) return '{"actions":[]}';
    final answer = _extractContent(await _request([{'role':'system','content':'Eres el planificador de acciones de un asistente Android. Devuelve SOLO JSON válido con {"actions":[...]}. Acciones permitidas: {"type":"open_app","package":"..."}, {"type":"tap_text","text":"..."}, {"type":"tap_description","text":"..."}, {"type":"type_text","text":"..."}, {"type":"back"}, {"type":"home"}, {"type":"swipe","direction":"up|down|left|right"}. Para Instagram usa com.instagram.android. No inventes paquetes salvo que sean conocidos. No escribas explicaciones. Ejecuta únicamente lo pedido por el usuario.'},{'role':'user','content':text}], maxTokens: 1024, temperature: 0.1));
    if (answer.isEmpty) throw const FormatException('El plan de automatización llegó vacío.'); jsonDecode(answer); return answer;
  }

  Future<Map<String, dynamic>> _request(List<Map<String, String>> messages, {required int maxTokens, required double temperature}) async {
    final base = _settings.apiBaseUrl.trim().replaceFirst(RegExp(r'/$'), ''); final model = _settings.model.trim();
    if (base.isEmpty || model.isEmpty) throw const FormatException('Faltan la URL base o el modelo del proveedor de IA.');
    final uri = Uri.tryParse(base + '/chat/completions');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) throw const FormatException('La URL base del proveedor no es válida.');
    final body = <String,dynamic>{'model':model,'messages':messages,'stream':false,'max_tokens':maxTokens,'temperature':temperature,'chat_template_kwargs':{'enable_thinking':false}};
    http.Response response;
    try { response = await _post(uri, body); } on SocketException catch (e) { throw Exception('No se pudo conectar con NVIDIA: ' + e.toString()); } on http.ClientException catch (e) { throw Exception('No se pudo conectar con el proveedor de IA: ' + e.toString()); }
    if (response.statusCode == 400) { final retry = Map<String,dynamic>.from(body)..remove('temperature'); response = await _post(uri, retry); }
    if (response.statusCode < 200 || response.statusCode >= 300) { final d=response.body.trim(); throw Exception('El proveedor de IA respondió con HTTP ' + response.statusCode.toString() + '.' + (d.isEmpty ? '' : ' Detalle: ' + (d.length > 1000 ? d.substring(0,1000) : d))); }
    if (response.body.trim().isEmpty) throw const FormatException('El proveedor de IA devolvió una respuesta vacía.');
    final decoded=jsonDecode(response.body); if (decoded is! Map) throw const FormatException('La respuesta de IA no tiene un formato válido.'); return Map<String,dynamic>.from(decoded);
  }

  String _extractContent(Map<String,dynamic> decoded) { final choices=decoded['choices']; if (choices is! List || choices.isEmpty || choices.first is! Map) throw const FormatException('La respuesta de IA no contiene choices.'); final message=choices.first['message']; if (message is! Map || message['content'] is! String) throw const FormatException('La respuesta de IA no contiene contenido.'); return (message['content'] as String).trim(); }
  Future<http.Response> _post(Uri uri, Map<String,dynamic> body) => _client.post(uri, headers:{'Accept':'application/json','Content-Type':'application/json',if (_settings.apiKey.trim().isNotEmpty) 'Authorization':'Bearer ' + _settings.apiKey.trim()}, body:jsonEncode(body)).timeout(const Duration(seconds:60));
}