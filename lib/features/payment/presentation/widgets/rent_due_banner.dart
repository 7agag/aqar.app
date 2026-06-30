import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/config/app_config.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:aqar/features/notifications/presentation/bloc/notification_state.dart';
import 'package:aqar/features/payment/presentation/pages/invoice_payment_status_page.dart';
import 'package:aqar/features/payment/presentation/pages/kashier_web_view_page.dart';
import 'package:aqar/features/subscription/data/services/pending_payment_service.dart';
import 'package:aqar/injection_container.dart' as di;

class RentDueBanner extends StatefulWidget {
  const RentDueBanner({super.key});

  @override
  State<RentDueBanner> createState() => _RentDueBannerState();
}

class _RentDueBannerState extends State<RentDueBanner> {
  bool _paying = false;

  static const _actionableTypes = {'RENT_DUE_NOTICE', 'PAYMENT_OVERDUE'};

  String? _extractInvoiceId(String? metadata) {
    if (metadata == null) return null;
    try {
      final parsed = json.decode(metadata) as Map<String, dynamic>;
      final id = parsed['invoice_id'];
      return id?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _payInvoice(String invoiceId) async {
    if (_paying) return;
    setState(() => _paying = true);

    final pendingService = PendingPaymentService();
    await pendingService.savePendingInvoicePayment(invoiceId);
    if (!mounted) return;

    try {
      final dio = di.sl<ApiClient>().dio;
      final res = await dio.post('/api/payment/', data: {
        'invoice_id': invoiceId,
        'redirect': AppConfig.invoiceCallbackUrl(invoiceId),
      });
      final url = res.data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Missing payment URL');
      }
      if (!mounted) return;
      await KashierWebViewPage.open(context, url: url);
      if (!mounted) return;
      await pendingService.clearPendingInvoicePayment();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoicePaymentStatusPage(
            invoiceId: invoiceId,
          ),
        ),
      );
    } catch (e) {
      await pendingService.clearPendingInvoicePayment();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is! NotificationsLoaded) return const SizedBox.shrink();

        final actionable = state.notifications.where((n) {
          if (n.viewed) return false;
          if (!_actionableTypes.contains(n.type)) return false;
          return _extractInvoiceId(n.metadata) != null;
        }).toList();

        if (actionable.isEmpty) return const SizedBox.shrink();

        final priority = actionable.where(
          (n) => n.type == 'PAYMENT_OVERDUE',
        );
        final notification = priority.isNotEmpty
            ? priority.first
            : actionable.first;

        final invoiceId = _extractInvoiceId(notification.metadata) ?? '';
        final isOverdue = notification.type == 'PAYMENT_OVERDUE';

        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isOverdue
                  ? AppColors.error.withValues(alpha: 0.95)
                  : Colors.amber.shade700,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isOverdue
                            ? 'Rent payment overdue'
                            : 'Rent payment due soon',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body.isNotEmpty
                            ? notification.body
                            : 'Complete your rent invoice payment to keep the lease active.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _paying ? null : () => _payInvoice(invoiceId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _paying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navyBlue,
                            ),
                          )
                        : const Text(
                            'Pay Now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyBlue,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
