import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static Future<bool> canAuthenticate() async {
    if (kIsWeb) return false;
    final auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  static Future<BiometricType?> getBiometricType() async {
    if (kIsWeb) return null;
    final auth = LocalAuthentication();
    try {
      final available = await auth.getAvailableBiometrics();
      if (available.contains(BiometricType.face)) return BiometricType.face;
      if (available.contains(BiometricType.fingerprint)) return BiometricType.fingerprint;
      if (available.contains(BiometricType.iris)) return BiometricType.iris;
      return null;
    } catch (_) {
      return null;
    }
  }

  static String getBiometricLabel(BiometricType? type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Touch ID';
      case BiometricType.iris:
        return 'Iris';
      default:
        return 'Biometric';
    }
  }

  static IconData getBiometricIcon(BiometricType? type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face_retouching_natural;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.remove_red_eye;
      default:
        return Icons.fingerprint;
    }
  }

  static Future<bool> authenticate({
    String reason = 'Please authenticate to confirm this action',
  }) async {
    if (kIsWeb) return true;
    final auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      if (!canCheck && !isDeviceSupported) return false;
      return await auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
