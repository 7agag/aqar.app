import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/services/biometric_auth_service.dart';

class BiometricAuthGuard {
  static Future<bool> guard(
    BuildContext context, {
    required String reason,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: false,
      builder: (_) => _GuardSheet(reason: reason),
    ).then((r) => r ?? false);
  }
}

class _GuardSheet extends StatefulWidget {
  final String reason;
  const _GuardSheet({required this.reason});
  @override
  State<_GuardSheet> createState() => _GuardSheetState();
}

class _GuardSheetState extends State<_GuardSheet> {
  bool _isVerified = false;
  bool _isLoading = false;

  Future<void> _verify() async {
    setState(() => _isLoading = true);
    final ok = await BiometricAuthService.authenticate(reason: widget.reason);
    if (!mounted) return;
    if (ok) {
      setState(() => _isVerified = true);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => _isLoading = false);
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
                  : AppColors.navyBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isVerified ? Icons.check_circle : Icons.lock_outline,
              color: _isVerified ? AppColors.success : AppColors.navyBlue,
              size: 28,
            ),
          ),
          SizedBox(height: 16),
          Text(
            _isVerified ? 'Verified!' : 'Confirm Your Identity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _isVerified
                ? 'Processing your request...'
                : widget.reason,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (!_isVerified) ...[
            const SizedBox(height: 28),
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
          ],
        ],
      ),
    );
  }
}
