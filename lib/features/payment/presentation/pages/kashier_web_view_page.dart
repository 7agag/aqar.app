import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/payment/presentation/widgets/payment_web_overlay.dart';
import 'package:aqar/features/payment/presentation/mixins/payment_verification_mixin.dart';
import 'package:aqar/features/payment/presentation/pages/payment_result_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KashierWebViewPage extends StatefulWidget {
  final String url;
  final int? propertyId;
  final VerificationType? paymentType;

  const KashierWebViewPage({
    super.key,
    required this.url,
    this.propertyId,
    this.paymentType,
  });

  static Future<Map<String, String?>?> open(
    BuildContext context, {
    required String url,
    int? propertyId,
    VerificationType? paymentType,
  }) {
    if (kIsWeb) {
      return _openWeb(context, url,
          propertyId: propertyId, paymentType: paymentType);
    }
    return Navigator.push<Map<String, String?>>(
      context,
      MaterialPageRoute(
        builder: (_) => KashierWebViewPage(
          url: url,
          propertyId: propertyId,
          paymentType: paymentType,
        ),
      ),
    );
  }

  static Future<Map<String, String?>?> _openWeb(
    BuildContext context,
    String url, {
    int? propertyId,
    VerificationType? paymentType,
  }) async {
    final confirmed = await PaymentWebOverlay.show(
      context,
      paymentUrl: url,
      propertyId: propertyId ?? 0,
      paymentType: paymentType ?? VerificationType.subscription,
    );
    return confirmed
        ? {'status': 'success', 'propertyId': '$propertyId', 'type': paymentType == VerificationType.sponsorship ? 'sponsor' : 'subscription'}
        : {'status': 'cancelled'};
  }

  static void navigateToResult(
    BuildContext context, {
    required String paymentStatus,
    required int propertyId,
    required String type,
    String? amount,
  }) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentResultScreen(
          paymentStatus: paymentStatus,
          propertyId: propertyId,
          type: type,
          amount: amount,
        ),
      ),
      (route) => route.isFirst,
    );
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
  Timer? _retryTimer;
  bool _paymentProcessed = false;
  int _retryCount = 0;
  static const int _maxAutoRetries = 1;

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
            if (request.url.contains('payment-callback')) {
              _processPaymentResponse(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (url.contains('payment-callback')) {
              _processPaymentResponse(url);
              return;
            }
            if (url.contains('kashier.io/error') ||
                url.contains('kashier.io/expired') ||
                url.contains('status=failed') ||
                url.contains('status=expired')) {
              if (!_paymentProcessed) {
                _handleExpiredSession();
              }
              return;
            }
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            _controller.runJavaScript('''
              (function(){
                var _open = window.open;
                window.open = function(url) {
                  if (url && url.indexOf('payment-callback') !== -1) {
                    window.location.href = url;
                    return null;
                  }
                  return _open.apply(window, arguments);
                };
              })();
            ''');
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
              _handleWebViewError(error.description);
            }
          },
        ),
      )
      ..loadRequest(uri);

    _clearWebViewCache();
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

  Future<void> _clearWebViewCache() async {
    try {
      await _controller.clearCache();
    } catch (_) {}
  }

  void _handleWebViewError(String description) {
    final isDnsError = description.contains('ERR_NAME_NOT_RESOLVED') ||
        description.contains('ERR_INTERNET_DISCONNECTED') ||
        description.contains('ERR_CONNECTION_TIMED_OUT') ||
        description.contains('ERR_CONNECTION_REFUSED');

    if (isDnsError && _retryCount < _maxAutoRetries) {
      _retryCount++;
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 1), _retry);
      return;
    }

    if (mounted) Navigator.pop(context, {'status': 'session_expired'});
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  void _processPaymentResponse(String urlString) {
    if (_paymentProcessed || !mounted) return;
    _paymentProcessed = true;

    final uri = Uri.parse(urlString);
    final paymentStatus = uri.queryParameters['status'] ??
        uri.queryParameters['paymentStatus'];
    final pid = uri.queryParameters['propertyId'];
    final amount = uri.queryParameters['amount'];
    final type = uri.queryParameters['type'] ??
        (widget.paymentType == VerificationType.sponsorship
            ? 'sponsor'
            : 'subscription');
    final propertyId = int.tryParse(pid ?? '') ?? widget.propertyId ?? 0;

    final result = <String, String?>{
      'status': paymentStatus?.toUpperCase() == 'SUCCESS' ? 'success' : 'failed',
      'propertyId': '$propertyId',
      'amount': amount,
      'type': type,
      'transactionId': uri.queryParameters['transactionId'],
    };

    Navigator.pop(context, result);
  }

  Future<void> _retry() async {
    if (!mounted) return;
    _retryTimer?.cancel();
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
    final uri = Uri.tryParse(widget.url);
    if (uri != null) await _controller.loadRequest(uri);
  }

  void _handleExpiredSession() {
    _loadingTimer?.cancel();
    _retryTimer?.cancel();
    if (mounted) Navigator.pop(context, {'status': 'session_expired'});
  }

  void _confirmClose() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel payment?'),
        content: const Text(
          'The current payment will be cancelled if you leave.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, cancel'),
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
            onPressed: _isLoading
                ? _confirmClose
                : () => Navigator.pop(context),
          ),
          title: const Text(
            'Secure Payment Gateway',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
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
                color: AppColors.navyBlue,
                minHeight: 2,
              ),
            Expanded(
              child: _hasError
                  ? _buildErrorState()
                  : WebViewWidget(controller: _controller),
            ),
          ],
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
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Unable to load payment page',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
