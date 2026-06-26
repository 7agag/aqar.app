import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
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
      );
    } catch (_) {
      return false;
    }
  }
}
