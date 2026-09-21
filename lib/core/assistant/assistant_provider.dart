import 'assistant_message.dart';

abstract interface class AssistantProvider {
  Future<AssistantMessage> sendMessage({
    required String text,
    required List<AssistantMessage> history,
  });
}
