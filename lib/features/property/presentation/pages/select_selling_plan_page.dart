import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/widgets/aqar_button.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/localization/app_strings.dart';
import 'package:aqar/injection_container.dart' as di;
import 'package:aqar/features/payment/presentation/pages/kashier_web_view_page.dart';
import 'package:dio/dio.dart';

class SelectSellingPlanPage extends StatefulWidget {
  final int propertyId;
  const SelectSellingPlanPage({super.key, required this.propertyId});

  @override
  State<SelectSellingPlanPage> createState() => _SelectSellingPlanPageState();
}

class _SelectSellingPlanPageState extends State<SelectSellingPlanPage> {
  int _selectedPlan = -1;

  static final _plans = [
    _PlanData(
      name: AppStrings.oneMonth,
      price: '250',
      features: [
        'High visibility in search results',
        'Featured listing badge',
      ],
    ),
    _PlanData(
      name: AppStrings.threeMonths,
      price: '700',
      isPopular: true,
      features: [
        'High visibility in search results',
        'Featured listing badge',
        'Top of search results',
        'Priority customer support',
      ],
    ),
    _PlanData(
      name: AppStrings.sixMonths,
      price: '1000',
      features: [
        'High visibility in search results',
        'Featured listing badge',
        'Top of search results',
        'Priority customer support',
        'Social media promotion',
        'Detailed analytics dashboard',
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

    try {
      final dio = di.sl<ApiClient>().dio;
      final response = await dio.post(
        '/api/sponser',
        data: {
          'property_id': widget.propertyId,
          'duration': _selectedDuration,
          'redirect': '${kIsWeb ? Uri.base.origin : 'https://aqar.dpdns.org'}/callback.html',
        },
      );

      final kashierUrl = response.data['url'] as String?;
      if (kashierUrl != null && mounted) {
        final result = await KashierWebViewPage.open(context, url: kashierUrl);
        if (!mounted) return;
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تفعيل الإعلان بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment not completed.'),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _handleConfirm,
              ),
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
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
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) => _buildPlanCard(i),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      color: Colors.white,
      child: Column(
        children: [
          Icon(Icons.rocket_launch, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text(
            'Boost Your Listing',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a promotion plan to get more visibility\nand sell your property faster.',
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
            offset: const Offset(0, 2),
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'MOST POPULAR',
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
            padding: const EdgeInsets.all(16),
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
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Promotion plan',
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
                const Divider(height: 24),
                ...plan.features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outlined,
                          size: 18,
                          color: isSelected
                              ? AppColors.success
                              : AppColors.textHint,
                        ),
                        const SizedBox(width: 10),
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
          onPressed: _selectedPlan == -1 ? null : _handleConfirm,
        ),
      ),
    );
  }
}

class _PlanData {
  final String name;
  final String price; // in EGP
  final bool isPopular;
  final List<String> features;

  const _PlanData({
    required this.name,
    required this.price,
    this.isPopular = false,
    required this.features,
  });
}
