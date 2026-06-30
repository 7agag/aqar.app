import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/injection_container.dart' as di;
import 'package:aqar/features/payment/presentation/mixins/payment_verification_mixin.dart';
import 'package:url_launcher/url_launcher.dart';

enum _WebOverlayStatus { opening, awaiting, verifying, success, retryPrompt }

class PaymentWebOverlay extends StatefulWidget {
  final String paymentUrl;
  final int propertyId;
  final VerificationType paymentType;

  const PaymentWebOverlay({
    super.key,
    required this.paymentUrl,
    required this.propertyId,
    required this.paymentType,
  });

  static Future<bool> show(
    BuildContext context, {
    required String paymentUrl,
    required int propertyId,
    required VerificationType paymentType,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Payment',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, anim1, anim2) => PopScope(
        canPop: false,
        child: PaymentWebOverlay(
          paymentUrl: paymentUrl,
          propertyId: propertyId,
          paymentType: paymentType,
        ),
      ),
    ).then((v) => v ?? false);
  }

  @override
  State<PaymentWebOverlay> createState() => _PaymentWebOverlayState();
}

class _PaymentWebOverlayState extends State<PaymentWebOverlay> {
  _WebOverlayStatus _status = _WebOverlayStatus.opening;
  final _dotCount = 12;
  int _filledDots = 0;

  Timer? _animationTimer;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const _maxPollAttempts = 10;

  @override
  void initState() {
    super.initState();
    _startOpeningSequence();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startOpeningSequence() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _filledDots = (_filledDots + 1) % (_dotCount + 1);
      });
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _status = _WebOverlayStatus.awaiting);
      _openPopup();
      _startPolling();
    });
  }

  Future<void> _openPopup() async {
    await launchUrl(
      Uri.parse(widget.paymentUrl),
      webOnlyWindowName: 'kashier_payment',
    );
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _pollAttempts++;
      if (_pollAttempts > _maxPollAttempts) {
        setState(() => _status = _WebOverlayStatus.retryPrompt);
        _pollTimer?.cancel();
        return;
      }
      _checkStatus();
    });
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final dio = di.sl<ApiClient>().dio;
      final res = await dio.get('/property/${widget.propertyId}');

      final isActivated = widget.paymentType == VerificationType.sponsorship
          ? res.data['is_sponsored'] == true
          : ['active', 'under_negotiation', 'sold']
              .contains(res.data['listing_status']);

      if (isActivated && mounted) {
        _pollTimer?.cancel();
        setState(() => _status = _WebOverlayStatus.success);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (_) {}
  }

  void _onRetry() {
    _pollAttempts = 0;
    setState(() => _status = _WebOverlayStatus.awaiting);
    _openPopup();
    _startPolling();
  }

  void _onClose() {
    Navigator.pop(context, false);
  }

  void _onRetryLater() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(height: 20),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildMessage(),
              const SizedBox(height: 24),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (_status) {
      case _WebOverlayStatus.success:
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, size: 44, color: AppColors.success),
        );
      case _WebOverlayStatus.retryPrompt:
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFE5A53B).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, size: 44, color: Color(0xFFE5A53B)),
        );
      default:
        return _buildDotsRing();
    }
  }

  Widget _buildDotsRing() {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _DotRingPainter(
          dotCount: _dotCount,
          filledCount: _filledDots,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    switch (_status) {
      case _WebOverlayStatus.opening:
        return Text(
          'Opening Payment Window',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        );
      case _WebOverlayStatus.awaiting:
      case _WebOverlayStatus.verifying:
        return Text(
          'Complete Payment',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        );
      case _WebOverlayStatus.success:
        return const Text(
          'Payment Confirmed!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        );
      case _WebOverlayStatus.retryPrompt:
        return const Text(
          'Not Yet Confirmed',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE5A53B),
          ),
        );
    }
  }

  Widget _buildMessage() {
    switch (_status) {
      case _WebOverlayStatus.opening:
        return Text(
          'Please wait while we prepare the payment window.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        );
      case _WebOverlayStatus.awaiting:
      case _WebOverlayStatus.verifying:
        if (widget.paymentType == VerificationType.sponsorship) {
          return Text(
            'Complete the payment in the popup window.\nWe\'ll verify it automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          );
        }
        return Text(
          'Complete the payment in the popup window.\nWe\'ll activate your listing automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        );
      case _WebOverlayStatus.success:
        if (widget.paymentType == VerificationType.sponsorship) {
          return Text(
            'Your boost has been activated successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          );
        }
        return Text(
          'Your listing subscription is now active!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        );
      case _WebOverlayStatus.retryPrompt:
        return Text(
          _pollAttempts > _maxPollAttempts
              ? 'We haven\'t received confirmation yet.\nThe popup may have been closed.'
              : 'The payment popup was closed before completion.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        );
    }
  }

  Widget _buildContent() {
    switch (_status) {
      case _WebOverlayStatus.opening:
      case _WebOverlayStatus.awaiting:
        return _buildProgressInfo();
      case _WebOverlayStatus.verifying:
        return const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _WebOverlayStatus.success:
        return const SizedBox.shrink();
      case _WebOverlayStatus.retryPrompt:
        return _buildRetryButtons();
    }
  }

  Widget _buildProgressInfo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Checking...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          'Auto-detecting payment in background',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              _pollTimer?.cancel();
              setState(() => _status = _WebOverlayStatus.retryPrompt);
            },
            child: const Text('Cancel Payment'),
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _onRetry,
            child: const Text('↻ Retry Payment'),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _onClose,
                  child: const Text('Close'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: TextButton(
                  onPressed: _onRetryLater,
                  child: const Text('Later'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DotRingPainter extends CustomPainter {
  final int dotCount;
  final int filledCount;
  final Color color;

  _DotRingPainter({
    required this.dotCount,
    required this.filledCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final dotRadius = 3.0;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * 3.14159 * i / dotCount) - 3.14159 / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      final isFilled = i < filledCount;

      canvas.drawCircle(
        Offset(x, y),
        dotRadius,
        Paint()..color = isFilled ? color : color.withValues(alpha: 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(_DotRingPainter old) => old.filledCount != filledCount;
}
