import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KashierWebViewPage extends StatefulWidget {
  final String url;

  const KashierWebViewPage({super.key, required this.url});

  static Future<bool?> open(BuildContext context, {required String url}) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KashierWebViewPage(url: url),
      ),
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
            if (request.url.startsWith('aqar://')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
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
  }

  Future<void> _retry() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isLoading = true;
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
