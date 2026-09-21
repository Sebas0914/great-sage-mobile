abstract interface class VoiceService {
  Future<void> startListening();
  Future<void> stopListening();
  Future<void> speak(String text);
}
