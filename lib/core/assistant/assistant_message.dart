enum MessageRole { user, assistant, system }

class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final MessageRole role;
  final String text;
  final DateTime createdAt;
}
