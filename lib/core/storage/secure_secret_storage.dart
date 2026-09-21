import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSecretStorage {
  SecureSecretStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const apiKeyKey = 'assistant_api_key_v2';
  final FlutterSecureStorage _storage;

  Future<String?> readApiKey() => _storage.read(key: apiKeyKey);

  Future<void> writeApiKey(String value) async {
    if (value.trim().isEmpty) {
      await clearApiKey();
      return;
    }
    await _storage.write(key: apiKeyKey, value: value.trim());
  }

  Future<void> clearApiKey() => _storage.delete(key: apiKeyKey);
}
