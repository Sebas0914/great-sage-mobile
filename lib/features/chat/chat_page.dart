import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final messages = <String>[];
  @override void dispose() { controller.dispose(); super.dispose(); }
  void send() {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    setState(() { messages.add(value); controller.clear(); });
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('GREAT SAGE')),
    body: Column(children: [
      Expanded(child: messages.isEmpty
        ? const Center(child: Text('Habla con GREAT SAGE'))
        : ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: messages.length,
            itemBuilder: (_, i) => Align(alignment: Alignment.centerRight,
              child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(messages[i]))))),
      SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12,4,12,12),
        child: Row(children: [
          Expanded(child: TextField(controller: controller, onSubmitted: (_) => send(), decoration: const InputDecoration(hintText: 'Escribe un mensaje'))),
          IconButton(onPressed: send, icon: const Icon(Icons.send)),
        ]))),
    ]),
  );
}
