import 'assistant_provider.dart';
import 'assistant_settings.dart';
import 'local_demo_provider.dart';
import 'open_ai_compatible_provider.dart';

class AssistantProviderFactory {
  const AssistantProviderFactory();

  AssistantProvider create(AssistantSettings settings) {
    switch (settings.provider) {
      case AssistantProviderType.localDemo:
        return const LocalDemoProvider();
      case AssistantProviderType.openAiCompatible:
        return OpenAiCompatibleProvider(settings: settings);
    }
  }
}
