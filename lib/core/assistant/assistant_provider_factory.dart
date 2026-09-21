import 'assistant_provider.dart';
import 'assistant_settings.dart';
import 'local_demo_provider.dart';

class AssistantProviderFactory {
  const AssistantProviderFactory();

  AssistantProvider create(AssistantSettings settings) {
    switch (settings.provider) {
      case AssistantProviderType.localDemo:
        return const LocalDemoProvider();
      case AssistantProviderType.openAiCompatible:
        throw UnsupportedError(
          'El proveedor compatible con OpenAI todavía no está implementado.',
        );
    }
  }
}
