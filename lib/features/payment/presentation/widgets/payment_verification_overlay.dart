import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/injection_container.dart' as di;

enum _OverlayStatus { verifying, success, expired }

class PaymentVerificationOverlay extends StatefulWidget {
  final int propertyId;
  final bool Function(Map<String, dynamic> data) isVerified;
  final int maxAttempts;
  final Duration interval;
  final String successTitle;
  final String successMessage;
  final String timeoutTitle;
  final String timeoutMessage;
  final bool isInstant;

  const PaymentVerificationOverlay({
    super.key,
    required this.propertyId,
    required this.isVerified,
    this.maxAttempts = 6,
    this.interval = const Duration(milliseconds: 2500),
    this.successTitle = 'Payment Confirmed!',
    this.successMessage = 'Your listing has been activated.',
    this.timeoutTitle = 'Still Processing',
    this.timeoutMessage =
        'Payment received but activation is taking longer than expected.',
    this.isInstant = false,
  });

  static bool _neverVerified(Map<String, dynamic> data) => false;

  const PaymentVerificationOverlay._instant({
    required this.successTitle,
    required this.successMessage,
  })  : propertyId = 0,
        isVerified = _neverVerified,
        maxAttempts = 6,
        interval = const Duration(milliseconds: 2500),
        timeoutTitle = '',
        timeoutMessage = '',
        isInstant = true;

  static Future<bool> show(
    BuildContext context, {
    required int propertyId,
    required bool Function(Map<String, dynamic> data) isVerified,
    int maxAttempts = 6,
    Duration interval = const Duration(milliseconds: 2500),
    String successTitle = 'Payment Confirmed!',
    String successMessage = 'Your listing has been activated.',
    String timeoutTitle = 'Still Processing',
    String timeoutMessage =
        'Payment received but activation is taking longer than expected.',
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Payment verification',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, anim1, anim2) => PopScope(
        canPop: false,
        child: PaymentVerificationOverlay(
          propertyId: propertyId,
          isVerified: isVerified,
          maxAttempts: maxAttempts,
          interval: interval,
          successTitle: successTitle,
          successMessage: successMessage,
          timeoutTitle: timeoutTitle,
          timeoutMessage: timeoutMessage,
        ),
      ),
    ).then((v) => v ?? false);
  }

  static Future<bool> showInstant(
    BuildContext context, {
    required String successTitle,
    required String successMessage,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Payment success',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, anim1, anim2) => PopScope(
        canPop: false,
        child: PaymentVerificationOverlay._instant(
          successTitle: successTitle,
          successMessage: successMessage,
        ),
      ),
    ).then((v) => v ?? true);
  }

  @override
  State<PaymentVerificationOverlay> createState() =>
      _PaymentVerificationOverlayState();
}

class _PaymentVerificationOverlayState
    extends State<PaymentVerificationOverlay>
    with TickerProviderStateMixin {
  _OverlayStatus _status = _OverlayStatus.verifying;
  int _elapsedAttempts = 0;
  int _statusMsgIndex = 0;
  Timer? _pollTimer;
  Timer? _msgTimer;
  late AnimationController _pulseCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _progressCtrl;
  double _progressTarget = 0;

  static const _statusMessages = [
    'Contacting payment provider...',
    'Verifying transaction...',
    'Almost there...',
  ];

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isInstant) {
      _status = _OverlayStatus.success;
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );
      _progressCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _entryCtrl.forward();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
      return;
    }

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryCtrl.forward();
    _startMessageCycle();
    _startPolling();
  }

  void _startMessageCycle() {
    _msgTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _statusMsgIndex = (_statusMsgIndex + 1) % _statusMessages.length;
      });
    });
  }

  void _startPolling() {
    int attempt = 0;
    _pollTimer = Timer.periodic(widget.interval, (timer) async {
      attempt++;
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedAttempts = attempt;
        _progressTarget = attempt / widget.maxAttempts;
      });
      _progressCtrl.animateTo(
        _progressTarget,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );

      try {
        final dio = di.sl<ApiClient>().dio;
        final res = await dio.get('/property/${widget.propertyId}');
        if (widget.isVerified(res.data as Map<String, dynamic>)) {
          timer.cancel();
          _msgTimer?.cancel();
          _pulseCtrl.stop();
          if (!mounted) return;
          setState(() => _status = _OverlayStatus.success);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context, true);
          });
          return;
        }
      } catch (_) {}

      if (attempt >= widget.maxAttempts) {
        timer.cancel();
        _msgTimer?.cancel();
        _pulseCtrl.stop();
        if (!mounted) return;
        setState(() => _status = _OverlayStatus.expired);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgTimer?.cancel();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _entryCtrl,
              builder: (_, child) => Opacity(
                opacity: _entryCtrl.value,
                child: Transform.translate(
                  offset: Offset(
                      0, 40 * (1 - Curves.easeOutCubic.transform(_entryCtrl.value))),
                  child: child,
                ),
              ),
              child: _buildCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: _buildIconContent(),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _titleText,
              key: ValueKey('${_status}_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _subtitleText,
              key: ValueKey('${_status}_msg_$_statusMsgIndex'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          if (_status == _OverlayStatus.verifying) ...[
            const SizedBox(height: 22),
            _buildProgressBar(),
            const SizedBox(height: 12),
            Text(
              '$_elapsedAttempts / ${widget.maxAttempts}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_status == _OverlayStatus.expired) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: AnimatedBuilder(
        animation: _progressCtrl,
        builder: (_, __) => LinearProgressIndicator(
          value: _progressCtrl.value,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 8,
        ),
      ),
    );
  }

  Widget _buildIconContent() {
    switch (_status) {
      case _OverlayStatus.verifying:
        return Stack(
          alignment: Alignment.center,
          key: const ValueKey('icon_verifying'),
          children: [
            CustomPaint(
              size: const Size(100, 100),
              painter: _DotRingPainter(
                filledDots: _elapsedAttempts == 0
                    ? 0
                    : (_elapsedAttempts * (12 / widget.maxAttempts))
                        .round()
                        .clamp(0, 12),
                totalDots: 12,
                emptyColor: Colors.grey[200]!,
                filledColor: AppColors.primary,
              ),
            ),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Transform.scale(
                scale: 1.0 + _pulseCtrl.value * 0.12,
                child: child,
              ),
              child: const Icon(
                Icons.payment_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
          ],
        );
      case _OverlayStatus.success:
        return Stack(
          alignment: Alignment.center,
          key: const ValueKey('icon_success'),
          children: [
            CustomPaint(
              size: const Size(100, 100),
              painter: _DotRingPainter(
                filledDots: 12,
                totalDots: 12,
                emptyColor: Colors.grey[200]!,
                filledColor: AppColors.primary,
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (_, value, __) => Transform.scale(
                scale: value,
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      case _OverlayStatus.expired:
        return Stack(
          alignment: Alignment.center,
          key: const ValueKey('icon_expired'),
          children: [
            CustomPaint(
              size: const Size(100, 100),
              painter: _DotRingPainter(
                filledDots: (_elapsedAttempts * (12 / widget.maxAttempts))
                    .round()
                    .clamp(0, 12),
                totalDots: 12,
                emptyColor: Colors.grey[200]!,
                filledColor: AppColors.navyBlue,
              ),
            ),
            const Icon(
              Icons.access_time_rounded,
              size: 48,
              color: AppColors.navyBlue,
            ),
          ],
        );
    }
  }

  String get _titleText {
    switch (_status) {
      case _OverlayStatus.verifying:
        return 'Verifying Payment';
      case _OverlayStatus.success:
        return widget.successTitle;
      case _OverlayStatus.expired:
        return widget.timeoutTitle;
    }
  }

  String get _subtitleText {
    switch (_status) {
      case _OverlayStatus.verifying:
        return _statusMessages[_statusMsgIndex];
      case _OverlayStatus.success:
        return widget.successMessage;
      case _OverlayStatus.expired:
        return widget.timeoutMessage;
    }
  }
}

class _DotRingPainter extends CustomPainter {
  final int filledDots;
  final int totalDots;
  final Color emptyColor;
  final Color filledColor;

  _DotRingPainter({
    required this.filledDots,
    required this.totalDots,
    required this.emptyColor,
    required this.filledColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final dotRadius = 4.0;

    for (int i = 0; i < totalDots; i++) {
      final angle = (i / totalDots) * 2 * pi - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawCircle(
        Offset(x, y),
        dotRadius,
        Paint()..color = i < filledDots ? filledColor : emptyColor,
      );
    }
  }

  @override
  bool shouldRepaint(_DotRingPainter old) =>
      old.filledDots != filledDots ||
      old.totalDots != totalDots ||
      old.emptyColor != emptyColor ||
      old.filledColor != filledColor;
}
