abstract interface class VoiceService {
  Future<bool> initialize();
  Future<bool> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'es_MX',
  });
  Future<void> stopListening();
  Future<void> speak(String text);
  Future<void> stopSpeaking();
}
