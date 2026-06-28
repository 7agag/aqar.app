import 'package:flutter/material.dart';
import 'package:aqar/features/payment/presentation/widgets/payment_verification_overlay.dart';

enum VerificationType { subscription, sponsorship }

mixin PaymentVerificationMixin<T extends StatefulWidget> on State<T> {
  Future<bool> verifyPaymentAfterWebView({
    required int propertyId,
    required bool Function(Map<String, dynamic> data) isVerified,
    int maxAttempts = 6,
    Duration interval = const Duration(milliseconds: 2500),
    String successTitle = 'Payment Confirmed!',
    String successMessage = 'Your listing has been activated.',
    String timeoutTitle = 'Still Processing',
    String timeoutMessage =
        'Payment received but activation is taking longer than expected.',
  }) async {
    if (!mounted) return false;
    return PaymentVerificationOverlay.show(
      context,
      propertyId: propertyId,
      isVerified: isVerified,
      maxAttempts: maxAttempts,
      interval: interval,
      successTitle: successTitle,
      successMessage: successMessage,
      timeoutTitle: timeoutTitle,
      timeoutMessage: timeoutMessage,
    );
  }

  Future<bool> showPaymentSuccess({
    String successTitle = 'Payment Confirmed!',
    String successMessage = 'Your payment was successful.',
  }) async {
    if (!mounted) return false;
    return PaymentVerificationOverlay.showInstant(
      context,
      successTitle: successTitle,
      successMessage: successMessage,
    );
  }
}
