import 'package:shared_preferences/shared_preferences.dart';

class AiUnreadService {
  static const _key = 'ai_has_unread';

  Future<bool> get hasUnread async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setHasUnread(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  Future<void> clear() async {
    await setHasUnread(false);
  }
}
