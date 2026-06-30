import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appThemeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
final appLocaleNotifier = ValueNotifier<String>('en');
final themeAnimProgress = ValueNotifier<double>(0.0);

class AppSettingsManager {
  static const _themeKey = 'app_theme_mode';
  static const _localeKey = 'locale';

  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeKey);
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey,
        mode == ThemeMode.dark ? 'dark' : 'light');
  }

  static Future<void> saveLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }
}
