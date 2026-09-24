import '../../core/assistant/assistant_message.dart';
import '../../core/assistant/assistant_provider.dart';
import '../../core/assistant/assistant_provider_factory.dart';
import '../../core/assistant/assistant_settings_repository.dart';
import '../../core/assistant/speech_translation_provider.dart';
import '../../core/automation/android_automation_service.dart';
import '../../core/automation/automation_provider.dart';
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
  final _automation = const AndroidAutomationService();

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

  bool _looksLikeAutomation(String text) {
    final t = text.toLowerCase();
    const words = ['abre ', 'abrir ', 'manda ', 'mandar ', 'envía ', 'enviar ', 'escribe en ', 'entra a ', 'pulsa ', 'toca ', 'haz clic', 'desliza ', 'abre instagram', 'en instagram'];
    return words.any(t.contains);
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

      final automationProvider = provider is AutomationProvider ? provider as AutomationProvider : null;
      if (_looksLikeAutomation(text) && automationProvider != null) {
        final enabled = await _automation.isEnabled();
        if (!enabled) {
          await _overlay.setSubtitle('Activa el acceso de accesibilidad de GREAT SAGE para controlar otras apps.');
          await _automation.openSettings();
          await Future<void>.delayed(const Duration(seconds: 2));
          await _overlay.setSubtitle('');
          await _runtime.setMood(RaphaelMood.neutral);
          return;
        }
        await _runtime.setMood(RaphaelMood.thinking);
        final plan = await automationProvider.planAutomation(text);
        final ok = await _automation.executePlan(plan);
        if (ok) {
          final done = AssistantMessage(
            role: MessageRole.assistant,
            text: 'Listo. Realicé los pasos que me pediste.',
            createdAt: DateTime.now(),
          );
          await history.save([...conversation, done]);
          await _runtime.setMood(RaphaelMood.speaking);
          await _overlay.setSubtitle(done.text);
          await _voice.speak('完了しました。');
          await _overlay.setSubtitle('');
          await _runtime.setMood(RaphaelMood.neutral);
          return;
        }
      }

      await _runtime.setMood(RaphaelMood.thinking);
      final reply = await provider.sendMessage(
        text: text,
        history: List.unmodifiable(conversation),
      );
      await history.save([...conversation, reply]);

      var spokenText = reply.text;
      final translator = provider is SpeechTranslationProvider ? provider as SpeechTranslationProvider : null;
      if (translator != null) {
        try {
          spokenText = await translator.translateForJapaneseSpeech(reply.text);
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
