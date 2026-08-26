import 'package:shared_preferences/shared_preferences.dart';

class LocalePreference {
  static const _key = 'app_locale';

  static Future<String?> getCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> setCode(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, code);
    }
  }
}
