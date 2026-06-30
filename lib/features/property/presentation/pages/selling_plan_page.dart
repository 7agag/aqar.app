import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/widgets/aqar_button.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/localization/app_strings.dart';
import 'package:aqar/injection_container.dart' as di;
import 'package:aqar/features/payment/presentation/pages/payment_gateway_page.dart';
import 'package:dio/dio.dart';
import 'package:aqar/core/config/app_config.dart';

class SellingPlanPage extends StatefulWidget {
  final int propertyId;
  const SellingPlanPage({super.key, required this.propertyId});

  @override
  State<SellingPlanPage> createState() => _SellingPlanPageState();
}

class _SellingPlanPageState extends State<SellingPlanPage> {
  int _selectedPlan = -1;
  bool _loading = false;

  static final _plans = [
    _PlanData(
      name: AppStrings.oneMonth,
      price: '120',
      features: [
        'Listing activated for 1 month',
        'Appears in search results',
      ],
    ),
    _PlanData(
      name: AppStrings.threeMonths,
      price: '360',
      isPopular: true,
      features: [
        'Listing activated for 3 months',
        'Appears in search results',
        'Featured badge',
        'Priority support',
      ],
    ),
    _PlanData(
      name: AppStrings.sixMonths,
      price: '600',
      features: [
        'Listing activated for 6 months',
        'Appears in search results',
        'Featured badge',
        'Priority support',
        'Social media promotion',
      ],
    ),
  ];

  int get _selectedDuration {
    switch (_selectedPlan) {
      case 0: return 1;
      case 1: return 3;
      case 2: return 6;
      default: return 1;
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedPlan == -1) return;
    setState(() => _loading = true);

    try {
      final dio = di.sl<ApiClient>().dio;

      // Phase 1: Create subscription
      final subResponse = await dio.post(
        '/subscription/${widget.propertyId}',
        data: {'planMonths': _selectedDuration},
      );

      final subscriptionId = subResponse.data['subscription_id'] as String?;
      if (subscriptionId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create subscription'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      // Phase 2: Get payment link
      final paymentResponse = await dio.post(
        '/api/payment/',
        data: {
          'subscription_id': subscriptionId,
          'redirect': AppConfig.subscriptionCallbackUrl(widget.propertyId, subscriptionId),
        },
      );

      final kashierUrl = paymentResponse.data['url'] as String?;
      if (kashierUrl != null && mounted) {
        setState(() => _loading = false);

        final success = await PaymentGatewayPage.open(
          context,
          itemName: _plans[_selectedPlan].name,
          amount: double.parse(_plans[_selectedPlan].price),
          generatePaymentUrl: () async => kashierUrl,
        );

        if (!mounted) return;
        Navigator.pop(context, success == true);
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get payment link'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Payment failed: ${e.response?.data?['message'] ?? e.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.selectPlan),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RadioGroup<int>(
              groupValue: _selectedPlan,
              onChanged: (v) => setState(() => _selectedPlan = v!),
              child: RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _buildPlanCard(i),
                ),
              ),
            ),
          ),
          if (_selectedPlan != -1) const SizedBox(height: 12),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
      color: Colors.white,
      child: Column(
        children: [
          Icon(Icons.verified, size: 40, color: AppColors.primary),
          SizedBox(height: 12),
          Text(
            'Activate Your Listing',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Choose a plan to activate your sale listing\nand reach more buyers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index) {
    final plan = _plans[index];
    final isSelected = _selectedPlan == index;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderLight,
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (plan.isPopular)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'BEST VALUE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Radio<int>(
                      value: index,
                      activeColor: AppColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Listing plan',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${plan.price} ${AppStrings.egp}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Divider(height: 24),
                ...plan.features.map(
                  (f) => Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outlined,
                          size: 18,
                          color: isSelected
                              ? AppColors.success
                              : AppColors.textHint,
                        ),
                        SizedBox(width: 10),
                        Text(
                          f,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AqarButton(
          text: AppStrings.payNow,
          isLoading: _loading,
          onPressed: (_selectedPlan == -1 || _loading) ? null : _handleConfirm,
        ),
      ),
    );
  }
}

class _PlanData {
  final String name;
  final String price;
  final bool isPopular;
  final List<String> features;

  const _PlanData({
    required this.name,
    required this.price,
    this.isPopular = false,
    required this.features,
  });
}
