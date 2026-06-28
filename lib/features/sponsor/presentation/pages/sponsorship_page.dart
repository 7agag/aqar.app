import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/widgets/aqar_button.dart';
import 'package:aqar/core/localization/app_strings.dart';
import 'package:aqar/core/config/app_config.dart';
import 'package:aqar/features/payment/presentation/pages/kashier_web_view_page.dart';
import 'package:aqar/features/payment/presentation/mixins/payment_verification_mixin.dart';
import 'package:aqar/features/subscription/data/services/pending_payment_service.dart';
import 'package:aqar/injection_container.dart' as di;
import 'package:aqar/features/sponsor/presentation/bloc/sponsor_bloc.dart';

class SponsorshipPage extends StatefulWidget {
  final int propertyId;
  const SponsorshipPage({super.key, required this.propertyId});

  @override
  State<SponsorshipPage> createState() => _SponsorshipPageState();
}

class _SponsorshipPageState extends State<SponsorshipPage>
    with PaymentVerificationMixin<SponsorshipPage> {
  int _selectedPlan = -1;
  final _pendingService = PendingPaymentService();
  late final SponsorBloc _sponsorBloc;

  @override
  void initState() {
    super.initState();
    _sponsorBloc = di.sl<SponsorBloc>();
  }

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

  void _handleConfirm() async {
    if (_selectedPlan == -1) return;

    await _pendingService.savePendingSponsorshipPayment(widget.propertyId);
    if (!mounted) return;

    _sponsorBloc.add(
      CreateSponsorCheckout(
        propertyId: widget.propertyId,
        duration: _selectedDuration,
        redirect: AppConfig.sponsorshipCallbackUrl(widget.propertyId),
      ),
    );
  }

  void _onCheckoutReady(String url) {
    KashierWebViewPage.open(
      context,
      url: url,
      propertyId: widget.propertyId,
      paymentType: VerificationType.sponsorship,
    ).then((result) {
      if (!mounted) return;
      if (result == null || result['status'] == 'failed' || result['status'] == 'cancelled') return;
      final pid = int.tryParse(result['propertyId'] ?? '') ?? widget.propertyId;
      KashierWebViewPage.navigateToResult(
        context,
        paymentStatus: 'success',
        propertyId: pid,
        type: 'sponsor',
        amount: result['amount'],
      );
    });
  }

  void _onError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _sponsorBloc,
      child: BlocListener<SponsorBloc, SponsorState>(
        listener: (context, state) {
          if (state is SponsorCheckoutReady) {
            _onCheckoutReady(state.url);
          } else if (state is SponsorError) {
            _pendingService.clearPendingSponsorshipPayment();
            _onError(state.message);
          }
        },
        child: Scaffold(
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
              child: BlocBuilder<SponsorBloc, SponsorState>(
                builder: (context, state) {
                  final isLoading = state is SponsorLoading;

                  return Stack(
                    children: [
                      Opacity(
                        opacity: isLoading ? 0.4 : 1.0,
                        child: AbsorbPointer(
                          absorbing: isLoading,
                          child: RadioGroup<int>(
                            groupValue: _selectedPlan,
                            onChanged: (v) =>
                                setState(() => _selectedPlan = v!),
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _plans.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (_, i) => _buildPlanCard(i),
                            ),
                          ),
                        ),
                      ),
                      if (isLoading)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  );
                },
              ),
            ),
            if (_selectedPlan != -1) const SizedBox(height: 12),
            _buildBottomBar(),
          ],
        ),
      ),
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
        child: BlocBuilder<SponsorBloc, SponsorState>(
          builder: (context, state) {
            final isLoading = state is SponsorLoading;
            return AqarButton(
              text: isLoading ? 'Processing...' : AppStrings.payNow,
              onPressed:
                  (_selectedPlan == -1 || isLoading) ? null : _handleConfirm,
            );
          },
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
