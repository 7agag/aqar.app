import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/config/app_config.dart';
import 'package:aqar/injection_container.dart' as di;
import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/features/property/domain/entities/property_enums.dart';
import 'package:aqar/features/payment/presentation/pages/payment_gateway_page.dart';
import 'package:aqar/features/payment/presentation/mixins/payment_verification_mixin.dart';
import 'package:aqar/features/subscription/domain/entities/sale_subscription_state.dart';
import 'package:aqar/features/subscription/domain/entities/listing_subscription_record.dart';
import 'package:aqar/features/subscription/data/services/subscription_storage_service.dart';
import 'package:aqar/features/subscription/data/services/pending_payment_service.dart';
import 'package:aqar/features/subscription/data/services/property_override_service.dart';

class PropertySubscriptionPage extends StatefulWidget {
  final int propertyId;
  const PropertySubscriptionPage({super.key, required this.propertyId});

  @override
  State<PropertySubscriptionPage> createState() => _PropertySubscriptionPageState();
}

class _PropertySubscriptionPageState extends State<PropertySubscriptionPage>
    with PaymentVerificationMixin<PropertySubscriptionPage> {
  final _storageService = SubscriptionStorageService();
  final _pendingService = PendingPaymentService();

  PropertyEntity? _property;
  ListingSubscriptionRecord? _localSub;
  bool _loading = true;
  String? _error;
  int _selectedPlan = 1;
  bool _creating = false;
  bool _paying = false;
  bool _changingPlan = false;
  bool _isProcessingPayment = false;

  Timer? _autoPollTimer;

  static const _plans = [1, 3, 6];
  static const _planPrices = {1: 120, 3: 360, 6: 600};

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void dispose() {
    _autoPollTimer?.cancel();
    super.dispose();
  }

  static num? _parseNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  Future<void> _loadPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = di.sl<ApiClient>().dio;
      final res = await dio.get('/property/${widget.propertyId}');
      final data = res.data;
      PropertyEntity property;
      property = PropertyEntity(
        propertyId: (_parseNum(data['property_id']) ?? _parseNum(data['id']) ?? 0).toInt(),
        ownerId: (data['owner_id'] as String?) ?? '',
        propertyName: (data['property_name'] as String?) ?? '',
        propertyDesc: (data['property_desc'] as String?) ?? '',
        location: (data['location'] as String?) ?? '',
        pricingUnit: PricingUnit.fromValue(data['pricing_unit'] as String? ?? data['pricingUnit'] as String? ?? 'month'),
        priceValue: (_parseNum(data['price_value']) ?? _parseNum(data['priceValue']) ?? 0).toDouble(),
        pricePerDay: (_parseNum(data['price_per_day']) ?? _parseNum(data['pricePerDay']) ?? 0).toDouble(),
        size: (data['size'] as String?) ?? '',
        bedroomsNo: (_parseNum(data['bedrooms_no']) ?? _parseNum(data['bedroomsNo']) ?? 0).toInt(),
        bedsNo: (_parseNum(data['beds_no']) ?? _parseNum(data['bedsNo']) ?? 0).toInt(),
        bathroomsNo: (_parseNum(data['bathrooms_no']) ?? _parseNum(data['bathroomsNo']) ?? 0).toInt(),
        images: (data['images'] is List ? (data['images'] as List).cast<String>() : <String>[]),
        isVerified: data['is_verified'] == true || data['is_verified'] == 1,
        isAvailable: data['is_available'] == true || data['is_available'] == 1,
        isFurnished: data['is_furnished'] == true || data['is_furnished'] == 1,
        isSponsored: data['is_sponsored'] == true || data['is_sponsored'] == 1,
        isVisible: data['is_visible'] == true || data['is_visible'] == 1,
        listingType: ListingType.fromValue(data['property_type'] as String? ?? data['listingType'] as String? ?? 'for_rent'),
        rate: _parseNum(data['rate'])?.toDouble(),
        listingStatus: ListingStatus.fromValue(data['listing_status'] as String? ?? data['listingStatus'] as String?),
        listingExpiry: _parseDate(data, 'listing_expiry') ?? _parseDate(data, 'listingExpiry'),
        ownerFirstName: (data['owner_first_name'] as String?) ?? (data['ownerFirstName'] as String?),
        ownerSecondName: (data['owner_second_name'] as String?) ?? (data['ownerSecondName'] as String?),
        ownerEmail: (data['owner_email'] as String?) ?? (data['ownerEmail'] as String?),
      );

      final overrideService = PropertyOverrideService();
      if (await overrideService.isSponsored(property.propertyId)) {
        property = PropertyEntity(
          propertyId: property.propertyId,
          ownerId: property.ownerId,
          propertyName: property.propertyName,
          propertyDesc: property.propertyDesc,
          location: property.location,
          pricingUnit: property.pricingUnit,
          priceValue: property.priceValue,
          pricePerDay: property.pricePerDay,
          size: property.size,
          bedroomsNo: property.bedroomsNo,
          bedsNo: property.bedsNo,
          bathroomsNo: property.bathroomsNo,
          images: property.images,
          isVerified: property.isVerified,
          isAvailable: property.isAvailable,
          isFurnished: property.isFurnished,
          isSponsored: true,
          isVisible: property.isVisible,
          listingType: property.listingType,
          rate: property.rate,
          listingStatus: property.listingStatus,
          listingExpiry: property.listingExpiry,
          ownerFirstName: property.ownerFirstName,
          ownerSecondName: property.ownerSecondName,
          ownerEmail: property.ownerEmail,
        );
      }

      if (property.listingType != ListingType.forSale) {
        setState(() {
          _property = property;
          _error = 'This page is only available for sale listings.';
          _loading = false;
        });
        return;
      }

      final synced = await _storageService.syncStoredListingSubscriptionWithProperty(property);
      final stored = synced ?? await _storageService.getStoredListingSubscription(property.propertyId);
      if (stored == null) {
        await _storageService.fetchSubscriptionFromApi(property.propertyId);
      }
      final freshLocal = await _storageService.getStoredListingSubscription(property.propertyId);

      if (!mounted) return;
      setState(() {
        _property = property;
        _localSub = freshLocal;
        _selectedPlan = freshLocal?.planMonths ?? 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load subscription details.';
        _loading = false;
      });
      debugPrint('[PropertySubscriptionPage] _loadPage error: $e');
    }
  }

  DateTime? _parseDate(Map data, String key) {
    final v = data[key];
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  SaleSubscriptionState? get _uiState =>
      _property != null ? getSaleSubscriptionUiState(_property!, _localSub, null) : null;

  void _startAutoPoll() {
    _autoPollTimer?.cancel();
    _autoPollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadPage());
  }

  void _stopAutoPoll() {
    _autoPollTimer?.cancel();
    _autoPollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selling Plan'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⚠️', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final property = _property!;
    final uiState = _uiState;
    final isPending = uiState == SaleSubscriptionState.awaitingVerification ||
        uiState == SaleSubscriptionState.paymentPending;

    if (isPending && !_isProcessingPayment) {
      _startAutoPoll();
    } else {
      _stopAutoPoll();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadPage,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(property.propertyName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            SizedBox(height: 6),
            Text('Manage your selling plan subscription',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),

            const SizedBox(height: 24),
            _buildStatusCard(property, uiState),
            const SizedBox(height: 16),
            _buildSubscriptionDetailsCard(),
            const SizedBox(height: 16),
            _buildActionsCard(property, uiState),
            const SizedBox(height: 16),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(PropertyEntity property, SaleSubscriptionState? uiState) {
    String title;
    String message;
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (uiState) {
      case SaleSubscriptionState.awaitingVerification:
        title = 'Waiting for admin verification';
        message = 'Your selling plan is attached to the property, but payment stays locked until the admin verifies the listing.';
        bgColor = const Color(0xFFFFF8E1);
        borderColor = const Color(0xFFFFE082);
        textColor = const Color(0xFF8D6E00);
      case SaleSubscriptionState.paidAwaitingVerification:
        title = 'Listing fee paid';
        message = 'Payment was received, but the property still needs admin verification before it becomes public.';
        bgColor = const Color(0xFFE3F2FD);
        borderColor = const Color(0xFF90CAF9);
        textColor = const Color(0xFF1565C0);
      case SaleSubscriptionState.readyToPay:
        title = 'Ready for payment';
        message = 'Pay the listing fee to activate your subscription.';
        bgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFFA5D6A7);
        textColor = const Color(0xFF2E7D32);
      case SaleSubscriptionState.paymentPending:
        title = 'Payment in progress';
        message = 'We\'re waiting for payment confirmation. Use "Check Status" if you already completed the card step.';
        bgColor = const Color(0xFFE3F2FD);
        borderColor = const Color(0xFF90CAF9);
        textColor = const Color(0xFF1565C0);
      case SaleSubscriptionState.active:
        final expiry = _formatDate(property.listingExpiry?.toIso8601String());
        title = 'Subscription active';
        message = 'Your listing is active and visible to buyers. Expires on $expiry.';
        bgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFFA5D6A7);
        textColor = const Color(0xFF2E7D32);
      case SaleSubscriptionState.expired:
        title = 'Subscription expired';
        message = 'The listing is no longer active. The current backend does not support renewal.';
        bgColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFEF9A9A);
        textColor = const Color(0xFFC62828);
      case SaleSubscriptionState.missingSubscription:
        title = 'No subscription yet';
        message = 'Choose a selling plan to activate this property for buyers.';
        bgColor = Colors.white;
        borderColor = AppColors.borderLight;
        textColor = AppColors.textPrimary;
      default:
        title = '';
        message = '';
        bgColor = Colors.white;
        borderColor = AppColors.borderLight;
        textColor = AppColors.textPrimary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.8), height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetailsCard() {
    if (_localSub == null) return const SizedBox.shrink();

    final sub = _localSub!;
    final canChange = _uiState == SaleSubscriptionState.readyToPay;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subscription Details',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _detailRow('Plan', '${sub.planMonths} Month${sub.planMonths > 1 ? 's' : ''}',
              trailing: canChange ? _buildChangePlanButton() : null),
          _detailRow('Amount', 'EGP ${sub.amount.toInt()}'),
          _detailRow('Status', sub.paymentState.value),
          _detailRow('ID', sub.subscriptionId.length > 8 ? '${sub.subscriptionId.substring(0, 8).toUpperCase()}...' : sub.subscriptionId),
        ],
      ),
    );
  }

  Widget _buildChangePlanButton() {
    return GestureDetector(
      onTap: () => setState(() => _changingPlan = !_changingPlan),
      child: Text(
        _changingPlan ? 'Cancel' : 'Change',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          if (trailing != null)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              SizedBox(width: 8),
              trailing,
            ])
          else
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActionsCard(PropertyEntity property, SaleSubscriptionState? uiState) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (uiState == SaleSubscriptionState.missingSubscription) ...[
            Text('Select a Plan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            SizedBox(height: 16),
            _buildPlanSelector(),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _creating ? null : _handleCreateSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_creating ? 'Creating...' : 'Create Subscription'),
              ),
            ),
          ],
          if (uiState == SaleSubscriptionState.readyToPay) ...[
            if (_changingPlan) ...[
              Text('Change Plan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              SizedBox(height: 16),
              _buildPlanSelector(),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _creating ? null : _handleChangePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_creating ? 'Saving...' : 'Confirm Change'),
                ),
              ),
              SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _paying ? null : startPaymentFlow,
                icon: Icon(Icons.payment_rounded, size: 18),
                label: Text(_paying ? 'Preparing payment...' : 'Pay Listing Fee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (uiState == SaleSubscriptionState.paymentPending) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadPage,
                icon: Icon(Icons.refresh_rounded, size: 18),
                label: Text('Check Payment Status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadPage,
              icon: Icon(Icons.refresh_rounded, size: 18),
              label: Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Row(
      children: _plans.map((months) {
        final selected = _selectedPlan == months;
        final price = _planPrices[months]!;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPlan = months),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppColors.primary : AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Text('$months Month${months > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    )),
                  const SizedBox(height: 4),
                  Text('EGP $price',
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: selected ? const Color(0xFFFFD54F) : AppColors.primary,
                    )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What happens next',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _step(1, 'Add the sale property with a selling plan.'),
          _step(2, 'Wait for admin verification.'),
          _step(3, 'Pay the listing fee to activate your subscription.'),
          _step(4, 'Buyers can contact you through chat while active.'),
        ],
      ),
    );
  }

  Widget _step(int number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle,
            ),
            child: Center(child: Text('$number',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
          ),
          SizedBox(width: 10),
          Expanded(child: Text(text,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4))),
        ],
      ),
    );
  }


  Future<void> _handleCreateSubscription() async {
    setState(() => _creating = true);
    final sub = await _storageService.createSubscriptionForProperty(
      widget.propertyId, _selectedPlan,
    );
    if (!mounted) return;
    setState(() => _creating = false);
    if (sub != null) {
      setState(() => _localSub = sub);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription created. You can now pay the listing fee.'),
          backgroundColor: AppColors.success),
      );
      await _loadPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create subscription.'),
          backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleChangePlan() async {
    setState(() => _creating = true);
    try {
      await _storageService.deleteStoredListingSubscription(widget.propertyId);
      final sub = await _storageService.createSubscriptionForProperty(
        widget.propertyId, _selectedPlan,
      );
      if (!mounted) return;
      if (sub != null) {
        setState(() {
          _localSub = sub;
          _changingPlan = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan changed successfully.'),
            backgroundColor: AppColors.success),
        );
        await _loadPage();
      } else {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not change plan. A subscription already exists for this property.'),
            backgroundColor: AppColors.error),
        );
        await _loadPage();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change plan.'),
          backgroundColor: AppColors.error),
      );
      await _loadPage();
    }
  }

  Future<void> startPaymentFlow() async {
    if (_localSub == null || _paying) return;
    _stopAutoPoll();
    _isProcessingPayment = true;
    setState(() => _paying = true);

    try {
      await _pendingService.savePendingSubscriptionPayment(
        widget.propertyId, _localSub!.subscriptionId,
      );
      await _storageService.updateStoredListingSubscriptionState(
        widget.propertyId, ListingSubscriptionPaymentState.pending,
      );
      setState(() {
        _localSub = _localSub!.copyWith(paymentState: ListingSubscriptionPaymentState.pending);
      });

      await _executePayment();
    } catch (e) {
      await _cleanupPayment('Payment failed: $e');
    }
  }

  Future<void> _executePayment() async {
    final dio = di.sl<ApiClient>().dio;
    final res = await dio.post('/api/payment/', data: {
      'subscription_id': _localSub!.subscriptionId,
      'redirect': AppConfig.subscriptionCallbackUrl(
        widget.propertyId, _localSub!.subscriptionId,
      ),
    });

    final url = res.data['url'] as String?;
    if (url == null) throw Exception('Missing payment URL');

    if (!mounted) return;
    setState(() => _paying = false);
    // _isProcessingPayment stays true — prevents auto-poll while gateway open

    final paymentResult = await PaymentGatewayPage.open(
      context,
      itemName: 'Selling Plan (${_localSub!.planMonths}mo)',
      amount: _localSub!.amount.toDouble(),
      generatePaymentUrl: () async {
        final url = await _fetchFreshPaymentUrl();
        if (url == null) throw Exception('Failed to fetch payment URL');
        return url;
      },
      isVerified: (data) =>
          ['active', 'under_negotiation', 'sold']
              .contains(data['listing_status']),
      onPaymentSuccess: (pid) async {
        await _pendingService.clearPendingSubscriptionPayment();
        await _storageService.updateStoredListingSubscriptionState(
          widget.propertyId, ListingSubscriptionPaymentState.paid,
        );
      },
    );

    if (!mounted) return;
    _isProcessingPayment = false;

    if (paymentResult == true) {
      await _loadPage();
    } else {
      await _cleanupPayment(null);
    }
  }

  Future<void> _cleanupPayment(String? errorMessage) async {
    if (!mounted) return;
    _isProcessingPayment = false;
    setState(() => _paying = false);
    await _pendingService.clearPendingSubscriptionPayment();
    await _storageService.updateStoredListingSubscriptionState(
      widget.propertyId, ListingSubscriptionPaymentState.unpaid,
    );
    if (errorMessage != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage),
          backgroundColor: AppColors.error),
      );
    }
    await _loadPage();
  }

  Future<String?> _fetchFreshPaymentUrl() async {
    try {
      final dio = di.sl<ApiClient>().dio;
      final res = await dio.post('/api/payment/', data: {
        'subscription_id': _localSub!.subscriptionId,
        'redirect': AppConfig.subscriptionCallbackUrl(
          widget.propertyId, _localSub!.subscriptionId,
        ),
      });
      return res.data['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _formatDate(String? value) {
    if (value == null) return '—';
    final date = DateTime.tryParse(value);
    if (date == null) return '—';
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
}
