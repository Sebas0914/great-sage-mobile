import '../storage/app_storage.dart';
import 'assistant_settings.dart';

class AssistantSettingsRepository {
  AssistantSettingsRepository(this._storage);

  static const _providerKey = 'assistant_provider_v1';
  static const _baseUrlKey = 'assistant_base_url_v1';
  static const _apiKeyKey = 'assistant_api_key_v1';
  static const _modelKey = 'assistant_model_v1';

  final AppStorage _storage;

  Future<AssistantSettings> load() async {
    final providerName = await _storage.readString(_providerKey);
    final provider = AssistantProviderType.values.firstWhere(
      (value) => value.name == providerName,
      orElse: () => AssistantProviderType.localDemo,
    );

    return AssistantSettings(
      provider: provider,
      apiBaseUrl: await _storage.readString(_baseUrlKey) ?? '',
      apiKey: await _storage.readString(_apiKeyKey) ?? '',
      model: await _storage.readString(_modelKey) ?? '',
    );
  }

  Future<void> save(AssistantSettings settings) async {
    await _storage.writeString(_providerKey, settings.provider.name);
    await _storage.writeString(_baseUrlKey, settings.apiBaseUrl.trim());
    await _storage.writeString(_apiKeyKey, settings.apiKey.trim());
    await _storage.writeString(_modelKey, settings.model.trim());
  }

  Future<void> clear() async {
    await _storage.remove(_providerKey);
    await _storage.remove(_baseUrlKey);
    await _storage.remove(_apiKeyKey);
    await _storage.remove(_modelKey);
  }
}
