import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/services/biometric_auth_service.dart';

class BiometricAuthGuard {
  static Future<bool> guard(
    BuildContext context, {
    required String reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return false;
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? true;

    if (biometricEnabled && await BiometricAuthService.canAuthenticate()) {
      if (!context.mounted) return false;
      return showModalBottomSheet<bool>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: false,
        builder: (_) => _BiometricSheet(reason: reason),
      ).then((r) => r ?? false);
    }

    if (!context.mounted) return false;
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: false,
      builder: (_) => _FallbackSheet(reason: reason),
    ).then((r) => r ?? false);
  }
}

class _BiometricSheet extends StatefulWidget {
  final String reason;
  const _BiometricSheet({required this.reason});
  @override
  State<_BiometricSheet> createState() => _BiometricSheetState();
}

class _BiometricSheetState extends State<_BiometricSheet> {
  bool _isVerified = false;
  bool _isLoading = false;
  bool _hasError = false;

  Future<void> _verify() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final ok = await BiometricAuthService.authenticate(reason: widget.reason);
    if (!mounted) return;
    if (ok) {
      setState(() => _isVerified = true);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _isVerified
                  ? AppColors.success.withValues(alpha: 0.1)
                  : _hasError
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.navyBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isVerified
                  ? Icons.check_circle
                  : _hasError
                      ? Icons.error_outline
                      : Icons.fingerprint,
              color: _isVerified
                  ? AppColors.success
                  : _hasError
                      ? AppColors.error
                      : AppColors.navyBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isVerified
                ? 'Verified!'
                : _hasError
                    ? 'Verification Failed'
                    : 'Confirm Your Identity',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasError
                ? 'Could not verify your identity. Please try again or continue without biometric.'
                : widget.reason,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          if (_isVerified)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify Now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context, true),
              child: const Text(
                'Continue without biometric',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FallbackSheet extends StatelessWidget {
  final String reason;
  const _FallbackSheet({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              color: AppColors.navyBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirm Your Identity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
