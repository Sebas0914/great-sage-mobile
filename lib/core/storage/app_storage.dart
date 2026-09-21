abstract interface class AppStorage {
  Future<void> writeString(String key, String value);
  Future<String?> readString(String key);
  Future<void> remove(String key);
}
