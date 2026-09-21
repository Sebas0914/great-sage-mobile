import 'package:flutter/material.dart';
import '../chat/chat_page.dart';
import '../raphael/raphael_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('GREAT SAGE Mobile')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 24),
      const Center(child: Icon(Icons.auto_awesome, size: 96)),
      const SizedBox(height: 16),
      Text('GREAT SAGE', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('Asistente móvil independiente', textAlign: TextAlign.center),
      const SizedBox(height: 40),
      FilledButton.icon(icon: const Icon(Icons.chat_bubble_outline), label: const Text('Abrir conversación'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage()))),
      const SizedBox(height: 12),
      OutlinedButton.icon(icon: const Icon(Icons.face_retouching_natural), label: const Text('Probar Raphael'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RaphaelPage()))),
    ]),
  );
}
