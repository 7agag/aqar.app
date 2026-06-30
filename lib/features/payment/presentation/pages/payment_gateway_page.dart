import 'package:flutter/material.dart';
import 'package:aqar/core/extensions/num_formatting.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/payment/presentation/pages/kashier_web_view_page.dart';
import 'package:aqar/features/payment/presentation/widgets/payment_verification_overlay.dart';

class PaymentGatewayPage extends StatefulWidget {
  final String itemName;
  final double amount;
  final Future<String> Function() generatePaymentUrl;
  final bool Function(Map<String, dynamic> data)? isVerified;
  final Future<void> Function(int propertyId)? onPaymentSuccess;

  const PaymentGatewayPage({
    super.key,
    required this.itemName,
    required this.amount,
    required this.generatePaymentUrl,
    this.isVerified,
    this.onPaymentSuccess,
  });

  static Future<bool?> open(
    BuildContext context, {
    required String itemName,
    required double amount,
    required Future<String> Function() generatePaymentUrl,
    bool Function(Map<String, dynamic> data)? isVerified,
    Future<void> Function(int propertyId)? onPaymentSuccess,
  }) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentGatewayPage(
          itemName: itemName,
          amount: amount,
          generatePaymentUrl: generatePaymentUrl,
          isVerified: isVerified,
          onPaymentSuccess: onPaymentSuccess,
        ),
      ),
    );
  }

  @override
  State<PaymentGatewayPage> createState() => _PaymentGatewayPageState();
}

class _PaymentGatewayPageState extends State<PaymentGatewayPage>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _errorMessage;

  late final AnimationController _animationController;
  late final Animation<double> _successScale;

  static const _navyBlue = Color(0xFF1A2744);

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
    _animationController.dispose();
    super.dispose();
  }

  double get _vat => widget.amount * 0.14;
  double get _total => widget.amount + _vat;

  Future<void> _handlePay() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final url = await widget.generatePaymentUrl();
      if (!mounted) return;

      if (url.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Failed to generate payment link';
        });
        return;
      }

      final result = await KashierWebViewPage.open(context, url: url);
      if (!mounted) return;

      if (result != null && result['status'] == 'success') {
        final pid = int.tryParse(result['propertyId'] ?? '') ?? 0;
        if (pid > 0) {
          final verify = widget.isVerified ??
              (data) => ['active', 'under_negotiation', 'sold']
                  .contains(data['listing_status']);
          final confirmed = await PaymentVerificationOverlay.show(
            context,
            propertyId: pid,
            isVerified: verify,
            successTitle: 'Payment Confirmed!',
            successMessage: 'Your payment has been processed successfully.',
          );
          if (!mounted) return;
          if (confirmed) {
            await widget.onPaymentSuccess?.call(pid);
          } else {
            setState(() {
              _isProcessing = false;
              _errorMessage = 'Payment could not be verified.';
            });
            return;
          }
        }
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
        _animationController.reset();
        _animationController.forward();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = result == null
              ? 'Payment cancelled'
              : 'Payment was not completed';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isProcessing) _showCancelDialog();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text(
            'بوابة الدفع الآمنة',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context, false),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.borderLight, height: 1),
          ),
        ),
        body: _isSuccess ? _buildSuccessView() : _buildCheckoutView(),
      ),
    );
  }

  void _showCancelDialog() {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          _buildInvoiceCard(),
          const SizedBox(height: 20),
          if (_errorMessage != null) _buildErrorBanner(),
          const SizedBox(height: 20),
          _buildPayButton(),
          const SizedBox(height: 16),
          _buildSecurityBadge(),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _navyBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: _navyBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ملخص الفاتورة',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.itemName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildAmountRow('السعر', widget.amount.formatWithCommas(decimals: 2)),
          const SizedBox(height: 8),
          _buildAmountRow('ضريبة 14%', _vat.formatWithCommas(decimals: 2)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildAmountRow(
            'الإجمالي',
            _total.formatWithCommas(decimals: 2),
            total: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String value, {bool total = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: total ? 14 : 13,
            fontWeight: total ? FontWeight.w600 : FontWeight.w400,
            color: total ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          '$value ج.م',
          style: TextStyle(
            fontSize: total ? 18 : 14,
            fontWeight: FontWeight.w700,
            color: total ? _navyBlue : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handlePay,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navyBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _navyBlue.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'ادفع الآن',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, size: 14, color: AppColors.textHint.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(
          'مدفوعات آمنة 256-bit SSL',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textHint.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.verified_rounded, size: 14, color: AppColors.textHint.withValues(alpha: 0.7)),
      ],
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _successScale,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'تمت عملية الدفع بنجاح',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'تم خصم مبلغ ${widget.amount.formatWithCommas(decimals: 2)} ج.م',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              children: [
                _buildReceiptRow('الخدمة', widget.itemName),
                const SizedBox(height: 10),
                _buildReceiptRow('المبلغ', '${widget.amount.formatWithCommas(decimals: 2)} ج.م'),
                const SizedBox(height: 10),
                _buildReceiptRow('طريقة الدفع', 'Kashier'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم إرسال إيصال الدفع إلى بريدك الإلكتروني',
            style: TextStyle(fontSize: 12, color: AppColors.textHint.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navyBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'العودة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}