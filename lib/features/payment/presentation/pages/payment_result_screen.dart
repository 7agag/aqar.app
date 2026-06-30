import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/subscription/data/services/pending_payment_service.dart';

class PaymentResultScreen extends StatefulWidget {
  final String paymentStatus;
  final int propertyId;
  final String type;
  final String? amount;

  const PaymentResultScreen({
    super.key,
    required this.paymentStatus,
    required this.propertyId,
    required this.type,
    this.amount,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  @override
  void initState() {
    super.initState();
    _clearPendingPayment();
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.paymentStatus == 'success';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSuccess
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.cancel,
                    size: 56,
                    color: isSuccess ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isSuccess ? _successTitle : 'Payment Failed',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSuccess ? _successMessage : _failureMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (widget.amount != null && isSuccess) ...[
                  const SizedBox(height: 20),
                  Text(
                    '${widget.amount} EGP',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _onDone(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isSuccess ? 'Continue' : 'Back',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _successTitle {
    if (widget.type == 'sponsor') return 'Boost Activated!';
    return 'Subscription Active!';
  }

  String get _successMessage {
    if (widget.type == 'sponsor') {
      return 'Your listing is now boosted.\nIt will appear at the top of search results.';
    }
    return 'Your listing subscription is now active.\nYour listing is visible to buyers.';
  }

  String get _failureMessage {
    return 'Something went wrong with your payment.\nPlease try again or use a different payment method.';
  }

  void _clearPendingPayment() {
    final service = PendingPaymentService();
    if (widget.type == 'sponsor') {
      service.clearPendingSponsorshipPayment();
    } else {
      service.clearPendingSubscriptionPayment();
    }
  }

  void _onDone(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
