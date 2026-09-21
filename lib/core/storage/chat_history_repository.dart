import 'dart:convert';

import '../assistant/assistant_message.dart';
import 'app_storage.dart';

class ChatHistoryRepository {
  ChatHistoryRepository(this._storage);

  static const _key = 'chat_history_v1';
  final AppStorage _storage;

  Future<List<AssistantMessage>> load() async {
    final raw = await _storage.readString(_key);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((item) {
            final roleName = item['role'];
            final text = item['text'];
            final createdAt = item['createdAt'];

            if (roleName is! String ||
                text is! String ||
                createdAt is! String) {
              return null;
            }

            final role = MessageRole.values.firstWhere(
              (value) => value.name == roleName,
              orElse: () => MessageRole.system,
            );
            final date = DateTime.tryParse(createdAt);
            if (date == null) return null;

            return AssistantMessage(
              role: role,
              text: text,
              createdAt: date,
            );
          })
          .whereType<AssistantMessage>()
          .toList(growable: true);
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<AssistantMessage> messages) async {
    final encoded = messages
        .map((message) => {
              'role': message.role.name,
              'text': message.text,
              'createdAt': message.createdAt.toIso8601String(),
            })
        .toList();

    await _storage.writeString(_key, jsonEncode(encoded));
  }

  Future<void> clear() async {
    await _storage.remove(_key);
  }
}
