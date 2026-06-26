import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:aqar/core/services/payment_listener.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KashierWebViewPage extends StatefulWidget {
  final String url;

  const KashierWebViewPage({super.key, required this.url});

  static Future<bool?> open(BuildContext context, {required String url}) {
    if (kIsWeb) {
      return _openWeb(context, url);
    }
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KashierWebViewPage(url: url),
      ),
    );
  }

  static Future<bool?> _openWeb(BuildContext context, String url) async {
    await launchUrl(
      Uri.parse(url),
      webOnlyWindowName: 'kashier_payment',
    );
    if (!context.mounted) return false;
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: false,
      builder: (_) => _WebPaymentSheet(url: url),
    ).then((r) => r ?? false);
  }

  @override
  State<KashierWebViewPage> createState() => _KashierWebViewPageState();
}

class _KashierWebViewPageState extends State<KashierWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      _hasError = true;
      _errorMessage = 'Invalid payment URL';
      _isLoading = false;
      _controller = WebViewController();
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.contains('payment-callback') ||
                request.url.contains('callback.html')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            _loadingTimer?.cancel();
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            _loadingTimer?.cancel();
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = error.description;
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(uri);

    _loadingTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isLoading) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Payment page took too long to load';
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _retry() async {
    _loadingTimer?.cancel();
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isLoading = true;
    });
    _loadingTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isLoading) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Payment page took too long to load';
          _isLoading = false;
        });
      }
    });
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmClose() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إلغاء عملية الدفع؟'),
        content: const Text('سيتم إلغاء عملية الدفع الجارية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('استمرار'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isLoading) _confirmClose();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textPrimary,
            onPressed: _isLoading ? _confirmClose : () => Navigator.pop(context, false),
          ),
          title: const Text(
            'بوابة الدفع الآمنة',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.borderLight, height: 1),
          ),
        ),
        body: Column(
          children: [
            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFFF0F0F0),
                color: Color(0xFF1A2744),
                minHeight: 2,
              ),
            Expanded(
              child: _hasError ? _buildErrorState() : WebViewWidget(controller: _controller),
            ),
          ],
        ),
        bottomNavigationBar: _hasError
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _openInBrowser,
                      child: const Text(
                        'فتح في المتصفح',
                        style: TextStyle(fontSize: 13, color: AppColors.textHint),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text(
              'تعذر تحميل صفحة الدفع',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2744),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('إعادة المحاولة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _openInBrowser,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('فتح في المتصفح', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebPaymentSheet extends StatefulWidget {
  final String url;
  const _WebPaymentSheet({required this.url});

  @override
  State<_WebPaymentSheet> createState() => _WebPaymentSheetState();
}

class _WebPaymentSheetState extends State<_WebPaymentSheet>
    with SingleTickerProviderStateMixin {
  String _state = 'initial';
  late final AnimationController _animationController;
  late final Animation<double> _successScale;
  StreamSubscription<Map<String, dynamic>>? _paymentSub;
  Timer? _verificationTimer;
  String _failureCode = '';

  static const Map<String, _FailureInfo> _failures = {
    'N': _FailureInfo(
      'Payment Declined',
      'Your bank declined the transaction.\nPlease try a different card or contact your bank.',
      Icons.cancel_rounded,
    ),
    'U': _FailureInfo(
      'Payment Declined by Issuer',
      'The card issuer declined this transaction.\nPlease contact your bank for details.',
      Icons.credit_card_off_rounded,
    ),
    'R': _FailureInfo(
      'Payment Reversed',
      'The payment was reversed.\nFunds will be returned within 3\u20135 business days.',
      Icons.swap_horiz_rounded,
    ),
    'E': _FailureInfo(
      'Payment Expired',
      'The payment session expired.\nPlease start a new payment.',
      Icons.timer_off_rounded,
    ),
    'AI': _FailureInfo(
      'Payment Under Review',
      'Your payment is being reviewed.\nWe will notify you once confirmed.',
      Icons.manage_search_rounded,
    ),
    'CANCELLED': _FailureInfo(
      'Payment Cancelled',
      'You cancelled the payment verification.\nTap Try Again when ready.',
      Icons.cancel_outlined,
    ),
  };

  static const _defaultFailure = _FailureInfo(
    'Payment Failed',
    'The payment could not be completed.\nPlease try again.',
    Icons.error_outline_rounded,
  );

  static const _timeoutFailure = _FailureInfo(
    'No Confirmation Received',
    'We didn\'t receive a payment confirmation.\nPlease check your payment status or try again.',
    Icons.hourglass_bottom_rounded,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _successScale = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _paymentSub?.cancel();
    _verificationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  static const _successStatuses = {'Y', 'approved', 'SUCCESS', '1'};

  void _onProceedToVerify() {
    setState(() => _state = 'verifying');
    final cached = PaymentListener.lastMessage;
    if (cached != null) {
      _handlePaymentStatus(cached['status'] as String? ?? '');
      return;
    }
    _paymentSub = PaymentListener.stream.listen((data) {
      final status = data['status'] as String? ?? '';
      _handlePaymentStatus(status);
    });
    _verificationTimer = Timer(const Duration(seconds: 60), () {
      _handlePaymentStatus('TIMEOUT');
    });
  }

  void _handlePaymentStatus(String status) {
    _paymentSub?.cancel();
    _verificationTimer?.cancel();
    if (_successStatuses.contains(status)) {
      if (!mounted) return;
      setState(() => _state = 'success');
      _animationController.reset();
      _animationController.forward();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      if (!mounted) return;
      setState(() {
        _state = 'failure';
        _failureCode = status;
      });
    }
  }

  void _onCancel() {
    _paymentSub?.cancel();
    _verificationTimer?.cancel();
    setState(() {
      _state = 'failure';
      _failureCode = 'CANCELLED';
    });
  }

  void _onTryAgain() {
    setState(() {
      _state = 'initial';
      _failureCode = '';
    });
  }

  void _onClose() {
    _paymentSub?.cancel();
    _verificationTimer?.cancel();
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Padding(
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (_state == 'initial') _buildInitial(),
            if (_state == 'verifying') _buildVerifying(),
            if (_state == 'success') _buildSuccess(),
            if (_state == 'failure') _buildFailure(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.navyBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline, size: 28, color: AppColors.navyBlue),
        ),
        const SizedBox(height: 16),
        const Text(
          'Secure Payment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'A new tab opened for payment.\nComplete it there, then tap Done.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => launchUrl(
              Uri.parse(widget.url),
              webOnlyWindowName: 'kashier_payment',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Open Payment Page',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _onProceedToVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, size: 20),
                SizedBox(width: 6),
                Text(
                  "Done \u2014 I've Completed Payment",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _onClose,
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifying() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.navyBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.navyBlue,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Verifying Payment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please wait while we confirm\nyour payment status\u2026',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        TextButton(
          onPressed: _onCancel,
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _successScale,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 40, color: AppColors.success),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Payment Successful!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your payment has been processed successfully.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildFailure() {
    final info = _failureCode == 'TIMEOUT'
        ? _timeoutFailure
        : _failures[_failureCode] ?? _defaultFailure;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(info.icon, size: 28, color: AppColors.error),
        ),
        const SizedBox(height: 16),
        Text(
          info.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          info.message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _onTryAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _onClose,
          child: const Text(
            'Close',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _FailureInfo {
  final String title;
  final String message;
  final IconData icon;

  const _FailureInfo(this.title, this.message, this.icon);
}
