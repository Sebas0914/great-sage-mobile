import 'package:shared_preferences/shared_preferences.dart';

import 'app_storage.dart';

class SharedPreferencesStorage implements AppStorage {
  SharedPreferencesStorage(this._preferences);

  final SharedPreferences _preferences;

  static Future<SharedPreferencesStorage> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesStorage(preferences);
  }

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<String?> readString(String key) async {
    return _preferences.getString(key);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}
