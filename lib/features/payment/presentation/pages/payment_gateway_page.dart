import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:aqar/core/services/escrow_service.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_state.dart';
import 'package:aqar/features/payment/domain/usecases/get_payment_link_usecase.dart';
import 'package:aqar/features/payment/presentation/pages/kashier_web_view_page.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_event.dart';
import 'package:aqar/injection_container.dart';

enum _PaymentTab { card, fawry, instapay, mobileWallet }

class PaymentGatewayPage extends StatefulWidget {
  final String itemName;
  final double amount;
  final int? propertyId;
  final String? requestId;
  final String? ownerId;

  const PaymentGatewayPage({
    super.key,
    required this.itemName,
    required this.amount,
    this.propertyId,
    this.requestId,
    this.ownerId,
  });

  @override
  State<PaymentGatewayPage> createState() => _PaymentGatewayPageState();
}

class _PaymentGatewayPageState extends State<PaymentGatewayPage>
    with SingleTickerProviderStateMixin {
  static const _navyBlue = Color(0xFF1A2744);
  static const _navyLight = Color(0xFF2D3F5E);

  _PaymentTab _selectedTab = _PaymentTab.card;
  final _formKey = GlobalKey<FormState>();

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _isProcessing = false;
  bool _isSuccess = false;
  bool _showCvv = false;
  bool _saveCard = false;

  final _cardNumberFocus = FocusNode();
  final _expiryFocus = FocusNode();
  final _cvvFocus = FocusNode();

  late final AnimationController _animationController;
  late final Animation<double> _successScale;

  String get _transactionId => '';
  String get _paymentTimestampStr => '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _successScale = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _cardNumberFocus.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String get _formattedAmount {
    final parts = widget.amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '$buf.${parts[1]}';
  }

  double get _vat => widget.amount * 0.14;
  double get _total => widget.amount + _vat;

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '$buf.${parts[1]}';
  }

  String get _cardBrand {
    final n = _cardNumberController.text.replaceAll(' ', '');
    if (n.startsWith('4')) return 'Visa';
    if (n.startsWith('5')) return 'Mastercard';
    if (n.startsWith('34') || n.startsWith('37')) return 'Amex';
    return '';
  }

  String get _maskedCardNumber {
    final raw = _cardNumberController.text.replaceAll(' ', '');
    if (raw.isEmpty) return '••••  ••••  ••••  ••••';
    final stars = raw.length > 4 ? raw.length - 4 : 0;
    final groups = <String>[];
    for (var i = 0; i < 4; i++) {
      if (i < 4 - (stars ~/ 4 + 1) && stars > 0) {
        groups.add('••••');
      } else {
        final start = i * 4;
        final end = start + 4;
        if (start < raw.length) {
          groups.add(raw.substring(start, end.clamp(0, raw.length)));
        }
      }
    }
    return groups.join('  ');
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
        body: _isSuccess ? _buildSuccessView() : _buildPaymentFlow(),
      ),
    );
  }

  String get _paymentMethodLabel {
    switch (_selectedTab) {
      case _PaymentTab.card:
        return 'بطاقة ائتمان';
      case _PaymentTab.fawry:
        return 'فوري';
      case _PaymentTab.instapay:
        return 'إنستاباي';
      case _PaymentTab.mobileWallet:
        return 'محفظة إلكترونية';
    }
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
            'تم خصم مبلغ $_formattedAmount ج.م',
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
                _buildReceiptRow('رقم العملية', _transactionId),
                const SizedBox(height: 10),
                _buildReceiptRow('التاريخ', _paymentTimestampStr),
                const SizedBox(height: 10),
                _buildReceiptRow('طريقة الدفع', _paymentMethodLabel),
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
            child: _buildNavyButton(
              text: 'العودة',
              onPressed: () => Navigator.pop(context, true),
            ),
          ),
        ],
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

  Widget _buildPaymentFlow() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              children: [
                _buildInvoiceCard(),
                const SizedBox(height: 20),
                _buildPaymentTabs(),
                const SizedBox(height: 20),
                if (_selectedTab == _PaymentTab.card) _buildCardSection(),
                if (_selectedTab == _PaymentTab.fawry) _buildFawryView(),
                if (_selectedTab == _PaymentTab.instapay) _buildInstaPayView(),
                if (_selectedTab == _PaymentTab.mobileWallet)
                  _buildMobileWalletView(),
                const SizedBox(height: 20),
                _buildSecurityBadge(),
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
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
          _buildAmountRow('السعر', _fmt(widget.amount)),
          const SizedBox(height: 8),
          _buildAmountRow('ضريبة 14%', _fmt(_vat)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildAmountRow(
            'الإجمالي',
            _fmt(_total),
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

  Widget _buildPaymentTabs() {
    final tabs = [
      (_PaymentTab.card, Icons.credit_card_rounded, 'بطاقة'),
      (_PaymentTab.fawry, Icons.account_balance_rounded, 'فوري'),
      (_PaymentTab.instapay, Icons.send_to_mobile_rounded, 'إنستاباي'),
      (_PaymentTab.mobileWallet, Icons.phone_iphone_rounded, 'محفظة'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _navyBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.$2,
                      size: 20,
                      color: isSelected ? Colors.white : AppColors.textHint,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab.$3,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardSection() {
    return Column(
      children: [
        _buildCardPreview(),
        const SizedBox(height: 16),
        _buildCardForm(),
      ],
    );
  }

  Widget _buildCardPreview() {
    return Container(
      width: double.infinity,
      height: 190,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [_navyBlue, _navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _navyBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChipIndicator(),
              _buildCardBrandIcon(),
            ],
          ),
          const Spacer(),
          Text(
            _maskedCardNumber,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اسم حامل البطاقة',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cardHolderController.text.isEmpty
                          ? 'YOUR NAME'
                          : _cardHolderController.text.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تاريخ الانتهاء',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _expiryController.text.isEmpty
                        ? 'MM/YY'
                        : _expiryController.text,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipIndicator() {
    return Container(
      width: 38,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 18,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBrandIcon() {
    final brand = _cardBrand;
    if (brand.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            brand == 'Visa'
                ? Icons.credit_card_rounded
                : Icons.credit_score_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            brand,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.credit_card_rounded, size: 18, color: _navyBlue),
                SizedBox(width: 8),
                Text(
                  'بيانات البطاقة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _cardHolderController,
              onChanged: (_) => setState(() {}),
              textDirection: TextDirection.ltr,
              decoration: _inputDecoration(
                label: 'اسم حامل البطاقة',
                hint: 'Cardholder Name',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'الحقل مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNumberController,
              focusNode: _cardNumberFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
              onChanged: (v) {
                setState(() {});
                if (v.replaceAll(' ', '').length >= 16) {
                  _expiryFocus.requestFocus();
                }
              },
              textDirection: TextDirection.ltr,
              decoration: _inputDecoration(
                label: 'رقم البطاقة',
                hint: '1234 5678 9012 3456',
                icon: Icons.credit_card_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'الحقل مطلوب';
                final cleaned = v.replaceAll(' ', '');
                if (cleaned.length < 13) return 'رقم البطاقة غير صالح';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    focusNode: _expiryFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryFormatter(),
                    ],
                    onChanged: (v) {
                      setState(() {});
                      if (v.replaceAll(RegExp(r'[^\d]'), '').length >= 4) {
                        _cvvFocus.requestFocus();
                      }
                    },
                    textDirection: TextDirection.ltr,
                    decoration: _inputDecoration(
                      label: 'تاريخ الانتهاء',
                      hint: 'MM/YY',
                      icon: Icons.calendar_today_rounded,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'مطلوب';
                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v.trim())) {
                        return 'MM/YY';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    focusNode: _cvvFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    obscureText: !_showCvv,
                    textDirection: TextDirection.ltr,
                    decoration: _inputDecoration(
                      label: 'CVV',
                      hint: '123',
                      icon: Icons.lock_outline_rounded,
                      suffix: GestureDetector(
                        onTap: () => setState(() => _showCvv = !_showCvv),
                        child: Icon(
                          _showCvv
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'مطلوب';
                      if (v.trim().length < 3) return 'غير صالح';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _saveCard,
                    onChanged: (v) => setState(() => _saveCard = v ?? false),
                    activeColor: _navyBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _saveCard
                      ? const Icon(Icons.bookmark_rounded,
                          size: 16, color: _navyBlue, key: ValueKey('saved'))
                      : const Icon(Icons.bookmark_outline_rounded,
                          size: 16, color: Color(0xFFB0B0B0), key: ValueKey('unsaved')),
                ),
                const SizedBox(width: 6),
                const Text(
                  'حفظ البطاقة للمدفوعات المستقبلية',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint.withValues(alpha: 0.6)),
      labelStyle: const TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
      floatingLabelStyle: const TextStyle(color: _navyBlue),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textHint),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFAFBFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _navyBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFawryView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1A5276).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              size: 32,
              color: Color(0xFF1A5276),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'فوري',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ادفع عبر أي فرع فوري أو من خلال تطبيق فوري',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          _buildCopyRow('رقم المرجع', '9245-6789-ABC'),
          const SizedBox(height: 12),
          _buildCopyRow('المبلغ', '$_formattedAmount ج.م'),
        ],
      ),
    );
  }

  Widget _buildInstaPayView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF6C3483).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send_to_mobile_rounded,
              size: 32,
              color: Color(0xFF6C3483),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'إنستاباي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'حوّل عبر إنستاباي باستخدام البيانات التالية',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          _buildCopyRow('رقم المحفظة', '0100 1234 5678'),
          const SizedBox(height: 12),
          _buildCopyRow('الاسم', 'AQAR Real Estate'),
        ],
      ),
    );
  }

  Widget _buildMobileWalletView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_iphone_rounded,
              size: 32,
              color: Color(0xFFE74C3C),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'المحفظة الإلكترونية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ادفع عبر فودافون كاش أو أي محفظة إلكترونية',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          _buildCopyRow('رقم المحفظة', '0109 8765 4321'),
          const SizedBox(height: 12),
          _buildCopyRow('المبلغ', '$_formattedAmount ج.م'),
        ],
      ),
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم نسخ $label'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _navyBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: _navyBlue,
              ),
            ),
          ),
        ],
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

  Widget _buildNavyButton({
    required String text,
    VoidCallback? onPressed,
    Widget? suffix,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navyBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _navyBlue.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 8),
              suffix,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF0F0F0)),
        ),
      ),
      child: _buildNavyButton(
        text: _isProcessing ? 'جاري الدفع...' : 'ادفع الآن وآمن',
        onPressed: _isProcessing ? null : () => _handlePay(),
        suffix: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.lock_rounded, size: 18, color: Colors.white),
      ),
    );
  }

  Future<void> _handlePay() async {
    if (_selectedTab == _PaymentTab.card) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isProcessing = true);

    try {
      final useCase = sl<GetPaymentLinkUseCase>();
      final linkResult = await useCase(
        GetPaymentLinkParams(
          invoiceId: 'invoice_${DateTime.now().millisecondsSinceEpoch}',
          redirect: 'aqar://payment-callback',
        ),
      );
      if (!mounted) return;

      linkResult.fold(
        (failure) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
        (link) async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => KashierWebViewPage(url: link.url),
            ),
          );
          if (!mounted) return;
          if (result == true) {
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthProfileLoaded && widget.requestId != null && widget.propertyId != null) {
              final ownerId = widget.ownerId;
              if (ownerId != null && ownerId.isNotEmpty) {
                await sl<EscrowService>().createLease(
                  requestId: widget.requestId!,
                  propertyId: widget.propertyId!,
                  renterId: authState.user.id,
                  ownerId: ownerId,
                );
                if (!mounted) return;
                context.read<RentRequestBloc>().add(const LoadRentRequests());
              }
            }
            setState(() {
              _isProcessing = false;
              _isSuccess = true;
            });
            HapticFeedback.mediumImpact();
            _animationController.reset();
            _animationController.forward();
          } else {
            setState(() => _isProcessing = false);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    final cursorOffset = formatted.length -
        (digits.length - newValue.selection.end) +
        (formatted.length - digits.length ~/ 4);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset.clamp(0, formatted.length)),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 2) {
      final formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
      final cursorOffset = formatted.length -
          (digits.length - newValue.selection.end) +
          (formatted.length > digits.length ? 1 : 0);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: cursorOffset.clamp(0, formatted.length)),
      );
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
