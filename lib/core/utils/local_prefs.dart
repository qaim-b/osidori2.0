import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  LocalPrefs._();

  static String themePresetKey(String userId) => 'prefs.theme_preset.$userId';
  static String activeGroupKey(String userId) => 'prefs.active_group.$userId';

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
