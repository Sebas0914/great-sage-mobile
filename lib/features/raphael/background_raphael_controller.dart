import '../../core/assistant/assistant_message.dart';
import '../../core/assistant/assistant_provider.dart';
import '../../core/assistant/assistant_provider_factory.dart';
import '../../core/assistant/assistant_settings_repository.dart';
import '../../core/assistant/speech_translation_provider.dart';
import '../../core/overlay/android_overlay_service.dart';
import '../../core/storage/chat_history_repository.dart';
import '../../core/storage/shared_preferences_storage.dart';
import '../../core/voice/device_voice_service.dart';
import 'raphael_runtime.dart';
import 'raphael_state.dart';

class BackgroundRaphaelController {
  BackgroundRaphaelController._();
  static final instance = BackgroundRaphaelController._();

  final _voice = DeviceVoiceService();
  final _overlay = const AndroidOverlayService();
  final _runtime = RaphaelRuntime.instance;

  AssistantProvider? _provider;
  ChatHistoryRepository? _history;
  bool _busy = false;
  bool _listening = false;

  Future<void> toggleListening() async {
    if (_busy) return;
    if (_listening) {
      await _voice.stopListening();
      _listening = false;
      await _runtime.setMood(RaphaelMood.neutral);
      return;
    }

    try {
      await _ensureReady();
      final started = await _voice.startListening(
        onResult: (text, isFinal) {
          if (isFinal && text.trim().isNotEmpty) {
            _listening = false;
            _voice.stopListening();
            _handleCommand(text.trim());
          } else if (text.trim().isNotEmpty) {
            _runtime.setMood(RaphaelMood.listening);
          }
        },
      );
      if (started) {
        _listening = true;
        await _runtime.setMood(RaphaelMood.listening);
      }
    } catch (_) {
      _listening = false;
      await _runtime.setMood(RaphaelMood.neutral);
    }
  }

  Future<void> _ensureReady() async {
    if (_provider != null && _history != null) return;
    final storage = await SharedPreferencesStorage.create();
    final settings = await AssistantSettingsRepository(storage).load();
    _provider = const AssistantProviderFactory().create(settings);
    _history = ChatHistoryRepository(storage);
  }

  Future<void> _handleCommand(String text) async {
    if (_busy) return;
    _busy = true;
    try {
      final provider = _provider;
      final history = _history;
      if (provider == null || history == null) return;

      final saved = await history.load();
      final user = AssistantMessage(
        role: MessageRole.user,
        text: text,
        createdAt: DateTime.now(),
      );
      final conversation = [...saved, user];

      await _runtime.setMood(RaphaelMood.thinking);
      final reply = await provider.sendMessage(
        text: text,
        history: List.unmodifiable(conversation),
      );
      await history.save([...conversation, reply]);

      var spokenText = reply.text;
      if (provider is SpeechTranslationProvider) {
        try {
          spokenText = await provider.translateForJapaneseSpeech(reply.text);
        } catch (_) {}
      }

      await _runtime.setMood(RaphaelMood.speaking);
      await _overlay.setSubtitle(reply.text);
      await _voice.speak(spokenText);
      await _overlay.setSubtitle('');
      await _runtime.setMood(RaphaelMood.neutral);
    } catch (_) {
      try {
        await _overlay.setSubtitle('');
        await _runtime.setMood(RaphaelMood.neutral);
      } catch (_) {}
    } finally {
      _busy = false;
    }
  }
}
