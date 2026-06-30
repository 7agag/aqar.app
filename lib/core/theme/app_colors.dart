import 'package:flutter/material.dart';
import 'package:aqar/core/services/app_settings_manager.dart';

class AppColors {
  // Primary - الذهبي بتاع AQAR (same in both modes)
  static const Color primary = Color(0xFFD4AF37);
  static const Color primaryLight = Color(0xFFE8B84B);
  static const Color primaryDark = Color.fromARGB(255, 179, 132, 16);

  static double get _t => themeAnimProgress.value.clamp(0.0, 1.0);

  // Background
  static const Color _backgroundLight = Color(0xFFF9FAFB);
  static const Color _backgroundDark = Color(0xFF0D1117);
  static Color get background =>
      Color.lerp(_backgroundLight, _backgroundDark, _t)!;

  static const Color _surfaceLight = Color(0xFFF5F4F0);
  static const Color _surfaceDark = Color(0xFF161B22);
  static Color get surfaceLight =>
      Color.lerp(_surfaceLight, _surfaceDark, _t)!;

  static const Color _cardDark = Color(0xFF1C2333);
  static Color get cardDark => _cardDark;

  // Text
  static const Color _textPrimaryLight = Color(0xFF020617);
  static const Color _textPrimaryDark = Color(0xFFE6EDF3);
  static Color get textPrimary =>
      Color.lerp(_textPrimaryLight, _textPrimaryDark, _t)!;

  static const Color _textSecondaryLight = Color(0xFF334155);
  static const Color _textSecondaryDark = Color(0xFF8B949E);
  static Color get textSecondary =>
      Color.lerp(_textSecondaryLight, _textSecondaryDark, _t)!;

  static const Color _textHintLight = Color(0xFFB0B0B0);
  static const Color _textHintDark = Color(0xFF484F58);
  static Color get textHint =>
      Color.lerp(_textHintLight, _textHintDark, _t)!;

  // Border
  static const Color border = Color(0xFFE8B84B);
  static const Color _borderLightLight = Color(0xFFF0E6C8);
  static const Color _borderLightDark = Color(0xFF30363D);
  static Color get borderLight =>
      Color.lerp(_borderLightLight, _borderLightDark, _t)!;

  // Status (same in both modes)
  static const Color error = Color(0xFFE24B4A);
  static const Color success = Color(0xFF1D9E75);

  // Accent (same in both modes)
  static const Color navyBlue = Color(0xFF1A2744);
}