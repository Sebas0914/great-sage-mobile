import 'package:flutter/material.dart';
import '../../core/assistant/assistant_message.dart';
import '../../core/assistant/local_demo_provider.dart';
import '../../core/storage/chat_history_repository.dart';
import '../../core/storage/shared_preferences_storage.dart';
import '../../core/voice/device_voice_service.dart';
import '../raphael/raphael_state.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final provider = const LocalDemoProvider();
  final voice = DeviceVoiceService();
  final messages = <AssistantMessage>[];

  ChatHistoryRepository? historyRepository;
  bool loadingHistory = true;
  bool sending = false;
  bool listening = false;
  bool speaking = false;
  bool voiceAutoSubmitting = false;
  RaphaelMood mood = RaphaelMood.neutral;
  String? voiceError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    voice.stopListening();
    voice.stopSpeaking();
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final storage = await SharedPreferencesStorage.create();
      final repository = ChatHistoryRepository(storage);
      final saved = await repository.load();
      if (!mounted) return;

      setState(() {
        historyRepository = repository;
        messages
          ..clear()
          ..addAll(saved);
        loadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loadingHistory = false;
        voiceError = 'No se pudo cargar el historial local.';
      });
    }
  }

  Future<void> _saveHistory() async {
    final repository = historyRepository;
    if (repository == null) return;

    try {
      await repository.save(List.unmodifiable(messages));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        voiceError = 'No se pudo guardar el historial local.';
      });
    }
  }

  Future<void> clearHistory() async {
    if (messages.isEmpty || sending) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar conversación'),
        content: const Text(
          'Se eliminarán todos los mensajes guardados en este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    messages.clear();
    await historyRepository?.clear();

    if (!mounted) return;
    setState(() {
      voiceError = null;
    });
  }

  Future<void> send() async {
    final value = controller.text.trim();
    if (value.isEmpty || sending || loadingHistory) return;

    if (listening) {
      await voice.stopListening();
    }

    controller.clear();
    setState(() {
      listening = false;
      voiceAutoSubmitting = false;
      voiceError = null;
      messages.add(AssistantMessage(
        role: MessageRole.user,
        text: value,
        createdAt: DateTime.now(),
      ));
      sending = true;
      mood = RaphaelMood.thinking;
    });
    await _saveHistory();

    try {
      final reply = await provider.sendMessage(
        text: value,
        history: List.unmodifiable(messages),
      );
      if (!mounted) return;

      setState(() {
        messages.add(reply);
        sending = false;
        speaking = true;
        mood = RaphaelMood.speaking;
      });
      await _saveHistory();

      await voice.speak(reply.text);
      if (!mounted) return;

      setState(() {
        speaking = false;
        mood = RaphaelMood.neutral;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        sending = false;
        speaking = false;
        voiceAutoSubmitting = false;
        mood = RaphaelMood.neutral;
        voiceError = 'No se pudo completar la respuesta.';
      });
      await _saveHistory();
    }
  }

  Future<void> submitVoiceResult(String text) async {
    final value = text.trim();
    if (value.isEmpty || sending || voiceAutoSubmitting) return;

    voiceAutoSubmitting = true;
    controller.text = value;
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );

    await voice.stopListening();
    if (!mounted) return;

    setState(() {
      listening = false;
      mood = RaphaelMood.neutral;
    });

    await send();
  }

  Future<void> toggleListening() async {
    if (sending || voiceAutoSubmitting || loadingHistory) return;

    if (listening) {
      await voice.stopListening();
      if (!mounted) return;
      setState(() {
        listening = false;
        mood = RaphaelMood.neutral;
      });
      return;
    }

    final started = await voice.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;

        controller.text = text;
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );

        if (isFinal) {
          setState(() {
            listening = false;
            mood = RaphaelMood.neutral;
          });

          if (text.trim().isNotEmpty) {
            Future<void>.microtask(() => submitVoiceResult(text));
          }
          return;
        }

        setState(() {
          listening = true;
          mood = RaphaelMood.listening;
        });
      },
    );

    if (!mounted) return;

    if (started) {
      setState(() {
        listening = true;
        voiceError = null;
        mood = RaphaelMood.listening;
      });
    } else {
      setState(() {
        listening = false;
        voiceError = 'No se pudo iniciar el reconocimiento de voz.';
        mood = RaphaelMood.neutral;
      });
    }
  }

  Future<void> stopVoice() async {
    await voice.stopSpeaking();
    if (!mounted) return;
    setState(() {
      speaking = false;
      mood = RaphaelMood.neutral;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20),
              const SizedBox(width: 8),
              const Text('GREAT SAGE'),
              const SizedBox(width: 10),
              if (loadingHistory)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  mood.name,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
          actions: [
            if (speaking)
              IconButton(
                tooltip: 'Detener voz',
                onPressed: stopVoice,
                icon: const Icon(Icons.stop_circle_outlined),
              ),
            IconButton(
              tooltip: 'Borrar conversación',
              onPressed: messages.isEmpty || sending ? null : clearHistory,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: Column(
          children: [
            if (mood != RaphaelMood.neutral)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  mood == RaphaelMood.thinking
                      ? 'Raphael está pensando…'
                      : mood == RaphaelMood.listening
                          ? 'Raphael está escuchando…'
                          : 'Raphael está hablando…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (voiceAutoSubmitting)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('Procesando lo que dijiste…'),
              ),
            if (voiceError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  voiceError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            Expanded(
              child: loadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? const Center(child: Text('Habla con GREAT SAGE'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (_, i) {
                            final message = messages[i];
                            final user = message.role == MessageRole.user;
                            return Align(
                              alignment: user
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(message.text),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (sending) const LinearProgressIndicator(minHeight: 2),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: listening
                          ? 'Detener micrófono'
                          : 'Hablar con GREAT SAGE',
                      onPressed: sending ||
                              voiceAutoSubmitting ||
                              loadingHistory
                          ? null
                          : toggleListening,
                      icon: Icon(
                        listening ? Icons.mic : Icons.mic_none,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        enabled: !loadingHistory && !voiceAutoSubmitting,
                        onSubmitted: (_) => send(),
                        decoration: InputDecoration(
                          hintText: listening
                              ? 'Escuchando…'
                              : 'Escribe un mensaje',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Enviar',
                      onPressed: sending ||
                              voiceAutoSubmitting ||
                              loadingHistory
                          ? null
                          : send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
