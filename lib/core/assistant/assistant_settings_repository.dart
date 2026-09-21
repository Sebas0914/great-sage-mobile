import '../storage/app_storage.dart';
import '../storage/secure_secret_storage.dart';
import 'assistant_settings.dart';

class AssistantSettingsRepository {
  AssistantSettingsRepository(
    this._storage, {
    SecureSecretStorage? secrets,
  }) : _secrets = secrets ?? SecureSecretStorage();

  static const _providerKey = 'assistant_provider_v1';
  static const _baseUrlKey = 'assistant_base_url_v1';
  static const _legacyApiKeyKey = 'assistant_api_key_v1';
  static const _modelKey = 'assistant_model_v1';

  final AppStorage _storage;
  final SecureSecretStorage _secrets;

  Future<AssistantSettings> load() async {
    final providerName = await _storage.readString(_providerKey);
    final provider = AssistantProviderType.values.firstWhere(
      (value) => value.name == providerName,
      orElse: () => AssistantProviderType.localDemo,
    );

    var apiKey = await _secrets.readApiKey();

    // Migrate an API key saved by older development builds.
    if (apiKey == null || apiKey.isEmpty) {
      final legacyKey = await _storage.readString(_legacyApiKeyKey);
      if (legacyKey != null && legacyKey.isNotEmpty) {
        apiKey = legacyKey;
        await _secrets.writeApiKey(legacyKey);
        await _storage.remove(_legacyApiKeyKey);
      }
    }

    return AssistantSettings(
      provider: provider,
      apiBaseUrl: await _storage.readString(_baseUrlKey) ?? '',
      apiKey: apiKey ?? '',
      model: await _storage.readString(_modelKey) ?? '',
    );
  }

  Future<void> save(AssistantSettings settings) async {
    await _storage.writeString(_providerKey, settings.provider.name);
    await _storage.writeString(_baseUrlKey, settings.apiBaseUrl.trim());
    await _secrets.writeApiKey(settings.apiKey);
    await _storage.writeString(_modelKey, settings.model.trim());
  }

  Future<void> clear() async {
    await _storage.remove(_providerKey);
    await _storage.remove(_baseUrlKey);
    await _secrets.clearApiKey();
    await _storage.remove(_legacyApiKeyKey);
    await _storage.remove(_modelKey);
  }
}
