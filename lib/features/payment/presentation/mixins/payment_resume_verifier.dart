import 'package:flutter/material.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/features/payment/presentation/pages/payment_result_screen.dart';
import 'package:aqar/features/subscription/data/services/pending_payment_service.dart';
import 'package:aqar/injection_container.dart' as di;

class PaymentResumeVerifier {
  final _pendingService = PendingPaymentService();
  final _maxAttempts = 8;
  final _interval = const Duration(seconds: 3);

  Future<void> verifyOnResume(GlobalKey<NavigatorState> navigatorKey) async {
    final subPending = await _pendingService.loadPendingSubscriptionPayment();
    final sponsorPending =
        await _pendingService.loadPendingSponsorshipPayment();

    if (subPending == null && sponsorPending == null) return;

    final propertyId =
        subPending?.propertyId ?? sponsorPending!.propertyId;
    final type = subPending != null ? 'subscription' : 'sponsor';

    final dio = di.sl<ApiClient>().dio;
    for (int i = 0; i < _maxAttempts; i++) {
      try {
        final res = await dio.get('/property/$propertyId');
        final data = res.data as Map<String, dynamic>;

        final isActivated = type == 'sponsor'
            ? data['is_sponsored'] == true
            : ['active', 'under_negotiation', 'sold']
                .contains(data['listing_status']);

        if (isActivated) {
          if (type == 'sponsor') {
            await _pendingService.clearPendingSponsorshipPayment();
          } else {
            await _pendingService.clearPendingSubscriptionPayment();
          }
          _navigateToResult(navigatorKey, propertyId, type);
          return;
        }
      } catch (_) {}

      if (i < _maxAttempts - 1) {
        await Future.delayed(_interval);
      }
    }

    if (type == 'sponsor') {
      await _pendingService.clearPendingSponsorshipPayment();
    } else {
      await _pendingService.clearPendingSubscriptionPayment();
    }
  }

  void _navigateToResult(
    GlobalKey<NavigatorState> navigatorKey,
    int propertyId,
    String type,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PaymentResultScreen(
            paymentStatus: 'success',
            propertyId: propertyId,
            type: type,
          ),
        ),
        (route) => route.isFirst,
      );
    });
  }
}
