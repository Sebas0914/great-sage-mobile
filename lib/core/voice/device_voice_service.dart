import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'voice_service.dart';

class DeviceVoiceService implements VoiceService {
  DeviceVoiceService({
    FlutterTts? textToSpeech,
    stt.SpeechToText? speechToText,
  })  : _tts = textToSpeech ?? FlutterTts(),
        _speech = speechToText ?? stt.SpeechToText();

  final FlutterTts _tts;
  final stt.SpeechToText _speech;
  bool _initialized = false;
  bool _speechAvailable = false;

  @override
  Future<bool> initialize() async {
    if (_initialized) return _speechAvailable;

    _speechAvailable = await _speech.initialize(
      onError: (_) => _speechAvailable = false,
    );

    await _tts.setLanguage('es-MX');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _initialized = true;
    return _speechAvailable;
  }

  @override
  Future<bool> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'es_MX',
  }) async {
    if (!await initialize()) return false;
    if (_speech.isListening) return true;

    try {
      await _speech.listen(
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
        ),
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
      );
      return _speech.isListening;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await initialize();
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
