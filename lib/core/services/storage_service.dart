import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;
  StorageService(this._prefs);

  static const _keyOnboarding = 'hasSeenOnboarding';

  bool get hasSeenOnboarding => _prefs.getBool(_keyOnboarding) ?? false;
  Future<bool> setHasSeenOnboarding(bool value) =>
      _prefs.setBool(_keyOnboarding, value);
}
