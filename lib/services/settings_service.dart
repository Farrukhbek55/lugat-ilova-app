import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _langKey        = 'lughat_lang';
  static const _darkKey        = 'lughat_dark';
  static const _notifKey       = 'lughat_notif';
  static const _permAskedKey   = 'lughat_perm_asked';

  Future<String> getLanguage() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_langKey) ?? 'uz';
  }
  Future<void> setLanguage(String lang) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_langKey, lang);
  }

  Future<bool> getDarkMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_darkKey) ?? false;
  }
  Future<void> setDarkMode(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_darkKey, v);
  }

  Future<bool> getNotifications() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_notifKey) ?? false;
  }
  Future<void> setNotifications(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_notifKey, v);
  }

  // Ruxsat bir marta so'ralgani saqlanadi
  Future<bool> getPermissionAsked() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_permAskedKey) ?? false;
  }
  Future<void> setPermissionAsked(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_permAskedKey, v);
  }
}
