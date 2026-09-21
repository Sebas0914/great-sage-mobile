import 'assistant_message.dart';
import 'assistant_provider.dart';

class LocalDemoProvider implements AssistantProvider {
  const LocalDemoProvider();

  @override
  Future<AssistantMessage> sendMessage({
    required String text,
    required List<AssistantMessage> history,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return AssistantMessage(
      role: MessageRole.assistant,
      text: 'Entendido. GREAT SAGE Mobile está listo para conectar un proveedor de IA.',
      createdAt: DateTime.now(),
    );
  }
}
