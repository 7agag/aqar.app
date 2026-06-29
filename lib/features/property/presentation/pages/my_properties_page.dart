import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/property_detail_navigator.dart';
import '../../../../core/services/biometric_auth_guard.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';
import 'package:aqar/features/sponsor/presentation/pages/sponsorship_page.dart';
import '../../../subscription/presentation/pages/property_subscription_page.dart';
import 'edit_property_page.dart';
import 'add_property_stepper_page.dart';
import '../../../subscription/domain/entities/sale_subscription_state.dart';

class MyPropertiesPage extends StatefulWidget {
  const MyPropertiesPage({super.key});

  @override
  State<MyPropertiesPage> createState() => _MyPropertiesPageState();
}

class _MyPropertiesPageState extends State<MyPropertiesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  final Set<int> _deletedIds = {};

  void _loadMyProperties() {
    context.read<PropertyBloc>().add(const GetMyPropertiesRequested());
  }

  Future<void> _openAddPropertyPage() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddPropertyStepperPage()),
    );
    if (!mounted) return;
    if (added == true) _loadMyProperties();
  }

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _loadMyProperties();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Properties',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: _openAddPropertyPage,
          ),
        ],
      ),
      body: BlocConsumer<PropertyBloc, PropertyState>(
        listener: (context, state) {
          if (state is PropertyDeleted) {
            _deletedIds.add(state.propertyId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success),
            );
            _loadMyProperties();
          } else if (state is PropertyOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success),
            );
            _loadMyProperties();
          } else if (state is PropertyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is PropertyLoading || state is PropertyInitial) {
            return _buildShimmer();
          }
          if (state is MyPropertiesLoaded) {
            final filtered = state.properties
                .where((p) => !_deletedIds.contains(p.propertyId) && p.isVisible)
                .toList();
            if (filtered.isEmpty) return _buildEmpty();
            return _buildList(filtered);
          }
          if (state is PropertyError) {
            return _buildError(state.message);
          }
          return _buildEmpty();
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => _ShimmerCard(controller: _shimmerCtrl),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined,
              size: 80, color: AppColors.textHint.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('You haven\'t added\nany properties yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  height: 1.4)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openAddPropertyPage,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Property'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: AppColors.error.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadMyProperties,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<PropertyEntity> properties) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadMyProperties();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return _PropertyCard(
            property: property,
            onTap: () =>
                propertyDetailNavigator.value = property.propertyId,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHIMMER CARD
// ---------------------------------------------------------------------------
class _ShimmerCard extends StatelessWidget {
  final AnimationController controller;
  const _ShimmerCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final opacity = 0.3 + (controller.value * 0.4);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(14)),
                child: Container(
                  width: 120,
                  height: 90,
                  color: Colors.grey.withValues(alpha: opacity),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 14,
                          width: 140,
                          decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: opacity),
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(
                          height: 11,
                          width: 100,
                          decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: opacity),
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 12),
                      Container(
                          height: 11,
                          width: 80,
                          decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: opacity),
                              borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// PROPERTY CARD
// ---------------------------------------------------------------------------
class _PropertyCard extends StatelessWidget {
  final PropertyEntity property;
  final VoidCallback onTap;
  const _PropertyCard({required this.property, required this.onTap});

  (String, Color) get _chip {
    if (property.isVisible == false) return ('Deleted', Colors.grey);

    if (property.listingType == ListingType.forSale) {
      return switch (getSaleSubscriptionUiState(property, null, null)) {
        SaleSubscriptionState.expired => ('Subscription Expired', Colors.grey),
        SaleSubscriptionState.paidAwaitingVerification => ('Paid · Pending Review', const Color(0xFF1565C0)),
        SaleSubscriptionState.awaitingVerification => ('Awaiting Review', const Color(0xFFFFA000)),
        SaleSubscriptionState.readyToPay => ('Verified · Unpaid', const Color(0xFF059669)),
        SaleSubscriptionState.paymentPending => ('Payment Processing', const Color(0xFF0284C7)),
        SaleSubscriptionState.missingSubscription => ('Subscription Missing', Colors.grey),
        SaleSubscriptionState.active => ('Listing Active ✓', AppColors.success),
      };
    }

    if (!property.isVerified) return ('Pending Review', const Color(0xFFFFA000));
    if (!property.isAvailable) return ('Unavailable', AppColors.error);
    return ('Active ✓', AppColors.success);
  }

  @override
  Widget build(BuildContext context) {
    final (chipLabel, chipColor) = _chip;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14)),
                  child: SizedBox(
                    width: 120,
                    height: 90,
                    child: property.images.isNotEmpty
                        ? Image.network(
                            property.images.first,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : Container(
                                        color: AppColors.surfaceLight,
                                        child: const Icon(Icons.home,
                                            color: AppColors.textHint)),
                            errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surfaceLight,
                                child: const Icon(Icons.home,
                                    color: AppColors.textHint)))
                        : Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.home,
                                color: AppColors.textHint)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(property.propertyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.7))),
                        const SizedBox(height: 8),
                        Text(
                            'EGP ${property.priceValue.toStringAsFixed(0)}${property.pricingUnitSuffix}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyBlue)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: chipColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: chipColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            chipLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: chipColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _ActionRow(property: property),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ACTION ROW
// ---------------------------------------------------------------------------
class _ActionRow extends StatefulWidget {
  final PropertyEntity property;
  const _ActionRow({required this.property});

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  final _scrollController = ScrollController();
  bool _isOverflowing = false;
  bool _atEnd = true;

  bool get _canManage =>
      widget.property.isVisible != false &&
      widget.property.listingStatus != ListingStatus.sold;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureOverflow());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final atEnd = _scrollController.offset >= maxScroll - 1;
    if (atEnd != _atEnd) {
      setState(() => _atEnd = atEnd);
    }
  }

  void _measureOverflow() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if ((maxScroll > 0) != _isOverflowing) {
        setState(() {
          _isOverflowing = maxScroll > 0;
          _atEnd = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSale = widget.property.listingType == ListingType.forSale;
    final showBoost = widget.property.isVerified &&
        widget.property.isAvailable &&
        !widget.property.isSponsored;
    final isDeleted = widget.property.isVisible == false;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: _isOverflowing
          ? Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: _buildButtons(context, isSale, showBoost, isDeleted),
                ),
                if (!_atEnd)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 24,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              AppColors.background.withValues(alpha: 0.9),
                              AppColors.background.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : Center(child: _buildButtons(context, isSale, showBoost, isDeleted)),
    );
  }

  Widget _buildButtons(BuildContext context, bool isSale, bool showBoost, bool isDeleted) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_canManage)
          _ActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: AppColors.navyBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      EditPropertyPage(property: widget.property)),
            ),
          ),
        if (_canManage) const SizedBox(width: 10),
        if (_canManage && isSale)
          _ActionButton(
            primary: true,
            icon: Icons.settings_outlined,
            label: 'Selling Plan',
            color: AppColors.navyBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PropertySubscriptionPage(
                      propertyId: widget.property.propertyId)),
            ),
          ),
        if (_canManage && showBoost)
          _ActionButton(
            primary: true,
            icon: Icons.auto_awesome,
            label: 'Boost',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SponsorshipPage(
                      propertyId: widget.property.propertyId)),
            ),
          ),
        if (_canManage && (isSale || showBoost))
          const SizedBox(width: 10),
        Opacity(
          opacity: isDeleted ? 0.4 : 1,
          child: _ActionButton(
            icon: Icons.delete_outline,
            label: isDeleted ? 'Deleted' : 'Delete',
            color: isDeleted ? AppColors.textHint : AppColors.error,
            onTap: isDeleted
                ? () {}
                : () => _confirmDelete(context),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text(
            'Are you sure you want to delete "${widget.property.propertyName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProperty(context);
            },
            child: Text('Delete',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteProperty(BuildContext context) async {
    final ok = await BiometricAuthGuard.guard(
      context,
      reason: 'Verify your identity to delete this property',
    );
    if (!ok || !context.mounted) return;
    context
        .read<PropertyBloc>()
        .add(DeletePropertyRequested(id: widget.property.propertyId));
  }
}

// ---------------------------------------------------------------------------
// ACTION BUTTON (pill style)
// ---------------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool primary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: primary ? Colors.white24 : color.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: primary
              ? null
              : BoxDecoration(
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(8),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: primary ? Colors.white : color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary ? Colors.white : color,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
