import 'package:flutter/material.dart';
import '../../core/assistant/assistant_message.dart';
import '../../core/assistant/assistant_provider.dart';
import '../../core/assistant/local_demo_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final provider = const LocalDemoProvider();
  final messages = <AssistantMessage>[];
  bool sending = false;

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  Future<void> send() async {
    final value = controller.text.trim();
    if (value.isEmpty || sending) return;
    controller.clear();
    setState(() {
      messages.add(AssistantMessage(role: MessageRole.user, text: value, createdAt: DateTime.now()));
      sending = true;
    });
    final reply = await provider.sendMessage(text: value, history: messages);
    if (!mounted) return;
    setState(() {
      messages.add(reply);
      sending = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('GREAT SAGE')),
    body: Column(children: [
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
                  alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                  child: Card(child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(message.text),
                  )),
                );
              },
            ),
      ),
      if (sending) const LinearProgressIndicator(minHeight: 2),
      SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(12,4,12,12),
        child: Row(children: [
          Expanded(child: TextField(
            controller: controller,
            onSubmitted: (_) => send(),
            decoration: const InputDecoration(hintText: 'Escribe un mensaje'),
          )),
          IconButton(onPressed: sending ? null : send, icon: const Icon(Icons.send)),
        ]),
      )),
    ]),
  );
}
