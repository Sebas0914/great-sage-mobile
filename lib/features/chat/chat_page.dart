import 'package:flutter/material.dart';
import '../../core/assistant/assistant_message.dart';
import '../../core/assistant/local_demo_provider.dart';
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

  bool sending = false;
  bool listening = false;
  bool speaking = false;
  bool voiceAutoSubmitting = false;
  RaphaelMood mood = RaphaelMood.neutral;
  String? voiceError;

  @override
  void dispose() {
    voice.stopListening();
    voice.stopSpeaking();
    controller.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final value = controller.text.trim();
    if (value.isEmpty || sending) return;

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
      });
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
    if (sending || voiceAutoSubmitting) return;

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
              child: messages.isEmpty
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
                      onPressed: sending || voiceAutoSubmitting
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
                      onPressed: sending || voiceAutoSubmitting ? null : send,
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
