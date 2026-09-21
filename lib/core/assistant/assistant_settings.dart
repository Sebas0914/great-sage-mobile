enum AssistantProviderType {
  localDemo,
  openAiCompatible,
}

class AssistantSettings {
  const AssistantSettings({
    this.provider = AssistantProviderType.localDemo,
    this.apiBaseUrl = '',
    this.apiKey = '',
    this.model = '',
  });

  final AssistantProviderType provider;
  final String apiBaseUrl;
  final String apiKey;
  final String model;

  AssistantSettings copyWith({
    AssistantProviderType? provider,
    String? apiBaseUrl,
    String? apiKey,
    String? model,
  }) {
    return AssistantSettings(
      provider: provider ?? this.provider,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }
}
