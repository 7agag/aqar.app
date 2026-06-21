import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/escrow_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/presentation/pages/chat_details_page.dart';
import '../../../favorite/presentation/bloc/favorite_bloc.dart';
import '../../../rent_request/presentation/bloc/rent_request_bloc.dart';
import '../../../rent_request/presentation/bloc/rent_request_event.dart';
import '../../../rent_request/presentation/bloc/rent_request_state.dart';
import 'package:aqar/features/review/presentation/bloc/review_bloc.dart';
import 'package:aqar/features/review/presentation/widgets/add_review_sheet.dart';
import 'package:aqar/features/review/presentation/widgets/review_list_widget.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../widgets/installment_calculator.dart';
import '../../../lease/presentation/pages/lease_list_page.dart';
import '../../../purchase_request/presentation/pages/purchase_request_list_page.dart';
import 'select_selling_plan_page.dart';
import '../widgets/listing_status_badge.dart';
import '../widgets/owner_trust_banner.dart';
import '../widgets/property_image_carousel.dart';
import 'full_screen_image_page.dart';

class PropertyDetailPage extends StatefulWidget {
  final int propertyId;
  final VoidCallback? onBack;
  const PropertyDetailPage({super.key, required this.propertyId, this.onBack});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  PropertyEntity? _property;
  bool _isLoading = true;
  DateTime? _rentCheckIn;
  int _rentDays = 1;
  int _rentMonths = 1;
  bool _aboutExpanded = false;

  DateTime? get _rentEndDate {
    if (_rentCheckIn == null) return null;
    final p = _property;
    if (p == null) return null;
    return p.pricingUnit == PricingUnit.day
        ? _rentCheckIn!.add(Duration(days: _rentDays))
        : _rentCheckIn!.add(Duration(days: _rentMonths * 30));
  }

  double get _rentTotalPrice {
    final p = _property;
    if (p == null || _rentCheckIn == null) return 0;
    return p.pricingUnit == PricingUnit.day
        ? _rentDays * p.pricePerDay
        : _rentMonths * p.priceValue;
  }

  bool get _rentValid {
    final p = _property;
    if (p == null || _rentCheckIn == null) return false;
    return p.pricingUnit == PricingUnit.day ? _rentDays > 0 : _rentMonths > 0;
  }

  @override
  void initState() {
    super.initState();
    context.read<PropertyBloc>().add(GetPropertyByIdRequested(id: widget.propertyId));
    context.read<FavoriteBloc>().add(GetFavoritesEvent());
    context.read<ReviewBloc>().add(GetReviews(propertyId: widget.propertyId));
  }

  void _toggleFavorite() {
    if (_isFavorite) {
      context.read<FavoriteBloc>().add(RemoveFavoriteEvent(widget.propertyId));
    } else {
      context.read<FavoriteBloc>().add(AddFavoriteEvent(widget.propertyId));
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  void _shareProperty() {
    final property = _property!;
    final url = '${AppConfig.webUrl}/property/${property.propertyId}';
    final price = _isForSale(property)
        ? 'EGP ${_fmt(property.priceValue)}'
        : 'EGP ${_fmt(property.priceValue)}/${property.pricingUnit.label}';
    final text = '$url\n\n${property.propertyName}\n${property.location}\n$price';

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Share Property', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareOption(ctx, icon: Icons.chat_bubble_outline_rounded, label: 'WhatsApp', color: const Color(0xFF25D366), onTap: () { Navigator.pop(ctx); _shareWhatsApp(text); }),
                  _shareOption(ctx, icon: Icons.copy_rounded, label: 'Copy Link', color: AppColors.navyBlue, onTap: () { Navigator.pop(ctx); _copyLink(url); }),
                  _shareOption(ctx, icon: Icons.share_rounded, label: 'More', color: AppColors.primary, onTap: () { Navigator.pop(ctx); _shareSystem(text); }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareOption(BuildContext ctx, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _shareWhatsApp(String text) async {
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _copyLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard'), duration: Duration(seconds: 2)));
    }
  }

  void _shareSystem(String text) {
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _openFullScreenGallery() {
    final property = _property!;
    if (property.images.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImagePage(images: property.images, initialIndex: _currentImageIndex)));
  }

  Future<void> _openGoogleMaps(PropertyEntity property) async {
    final lat = property.latitude;
    final lng = property.longitude;
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  bool _isForSale(PropertyEntity property) => property.listingType == ListingType.forSale;

  String _ownerDisplayName(PropertyEntity property) {
    final parts = [property.ownerFirstName, property.ownerSecondName].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'Property Owner';
    return parts.join(' ');
  }

  String _ownerInitials(PropertyEntity property) {
    final parts = _ownerDisplayName(property).split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'PO';
    final first = parts.first.characters.first.toUpperCase();
    final second = parts.length > 1 ? parts.last.characters.first.toUpperCase() : '';
    return '$first$second';
  }

  bool get _isOwner {
    final authState = context.read<AuthBloc>().state;
    if (_property == null) return false;
    return authState is AuthProfileLoaded && authState.user.id == _property!.ownerId;
  }

  String _fmt(double v) {
    final parts = v.toStringAsFixed(0).split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PropertyBloc, PropertyState>(
          listener: (context, state) {
            if (state is PropertyDetailLoaded) {
              setState(() { _property = state.property; _isLoading = false; });
            }
            if (state is PropertyError) setState(() => _isLoading = false);
          },
        ),
        BlocListener<FavoriteBloc, FavoriteState>(
          listener: (context, state) {
            if (_property == null) return;
            if (state is FavoriteLoaded) {
              final favIds = state.favorites.map((p) => p.propertyId).toSet();
              setState(() { _isFavorite = favIds.contains(_property!.propertyId); });
            }
          },
        ),
        BlocListener<RentRequestBloc, RentRequestState>(
          listener: (context, state) {
            if (state is RentRequestActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
              setState(() { _rentCheckIn = null; _rentDays = 1; _rentMonths = 1; });
            }
            if (state is RentRequestError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
      ],
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_property == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 72, color: AppColors.textHint.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('Could not load property', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.read<PropertyBloc>().add(GetPropertyByIdRequested(id: widget.propertyId)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final property = _property!;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildActionBar(property),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── 1. Header Gallery ──
              PropertyImageCarousel(
                images: property.images,
                currentIndex: _currentImageIndex,
                onIndexChanged: (i) => _currentImageIndex = i,
                onTap: _openFullScreenGallery,
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── 2. Basic Info (Price + Name) ──
                    _buildBasicInfo(property),
                    const SizedBox(height: 16),
                    // ── 3. Location ──
                    _buildLocation(property),
                    const SizedBox(height: 16),
                    // ── 4. Specs Row ──
                    _buildSpecsRow(property),
                    const SizedBox(height: 16),
                    // ── 5. About (Read More/Less) ──
                    _buildAbout(property),
                    const SizedBox(height: 16),
                    // ── 6. Property Details Grid ──
                    _buildDetailsGrid(property),
                    const SizedBox(height: 16),
                    // ── 7. Conditional Section (Owner / Sold / Installment) ──
                    _buildConditionalSection(property),
                    if (property.listingType == ListingType.forRent && !_isOwner && property.listingStatus != ListingStatus.sold) ...[
                      const SizedBox(height: 16),
                      _buildRentSection(property),
                    ],
                    const SizedBox(height: 16),
                    // ── 8. Location on Map ──
                    _buildMapSection(property),
                    const SizedBox(height: 16),
                    // ── 9. Ratings & Reviews ──
                    _buildRatingsSection(property),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
          // ── Overlay Buttons ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
              child: IconButton(
                onPressed: () { widget.onBack?.call(); if (widget.onBack == null) Navigator.pop(context); },
                icon: const Icon(Icons.arrow_back_rounded), color: AppColors.textPrimary,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: _toggleFavorite,
                    icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? AppColors.primary : AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                  child: IconButton(onPressed: _shareProperty, icon: const Icon(Icons.ios_share_outlined), color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Basic Info ──
  Widget _buildBasicInfo(PropertyEntity property) {
    final lease = di.sl<EscrowService>().getLeaseByProperty(property.propertyId);
    final isRented = property.listingType == ListingType.forRent && lease != null &&
        (lease.status == LeaseStatus.escrowActive || lease.status == LeaseStatus.tenantConfirmed || lease.status == LeaseStatus.completed);
    String priceText;
    if (_isForSale(property)) {
      priceText = '${AppStrings.egp} ${_fmt(property.priceValue)}';
    } else if (property.pricingUnit == PricingUnit.day) {
      priceText = '${AppStrings.egp} ${_fmt(property.priceValue)} ${AppStrings.perDay}';
    } else {
      priceText = '${AppStrings.egp} ${_fmt(property.priceValue)} ${AppStrings.perMonth}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property.propertyName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(priceText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const Spacer(),
              if (isRented) _buildRentedBadge()
              else ListingStatusBadge(property: property),
            ],
          ),
          const SizedBox(height: 12),
          OwnerTrustBanner(property: property),
        ],
      ),
    );
  }

  Widget _buildRentedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: const Text('Rented', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
    );
  }

  // ── 3. Location ──
  Widget _buildLocation(PropertyEntity property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _openGoogleMaps(property),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(property.location, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── 4. Specs Row ──
  Widget _buildSpecsRow(PropertyEntity property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _specCard(Icons.bed_rounded, '${property.bedroomsNo}', 'Bedrooms'),
          const SizedBox(width: 10),
          _specCard(Icons.bathtub_rounded, '${property.bathroomsNo}', 'Bathrooms'),
          const SizedBox(width: 10),
          _specCard(Icons.square_foot_rounded, property.size.isNotEmpty ? property.size.replaceAll(RegExp(r'[^0-9.]'), '') : '—', 'Area'),
          const SizedBox(width: 10),
          _specCard(Icons.king_bed_rounded, '${property.bedsNo}', 'Beds'),
        ],
      ),
    );
  }

  Widget _specCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.navyBlue),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }

  // ── 5. About with Read More ──
  Widget _buildAbout(PropertyEntity property) {
    final desc = property.propertyDesc;
    if (desc.isEmpty) return const SizedBox.shrink();
    const maxLines = 3;
    final needsToggle = desc.split('\n').length > maxLines || desc.length > 150;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.aboutProperty),
            const SizedBox(height: 10),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _aboutExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: Text(desc, maxLines: maxLines, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary)),
              secondChild: Text(desc, style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary)),
            ),
            if (needsToggle)
              GestureDetector(
                onTap: () => setState(() => _aboutExpanded = !_aboutExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _aboutExpanded ? 'Show less' : 'Read more',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── 6. Property Details Grid ──
  Widget _buildDetailsGrid(PropertyEntity property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Property Details'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _detailTile(Icons.home_work_outlined, 'Type', property.listingType == ListingType.forSale ? 'For Sale' : 'For Rent')),
                Expanded(child: _detailTile(Icons.weekend_outlined, 'Furnished', property.isFurnished ? 'Yes' : 'No')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _detailTile(Icons.verified_outlined, 'Verified', property.isVerified ? 'Verified' : 'Not Verified')),
                Expanded(child: _detailTile(Icons.attach_money_rounded, 'Pricing', _formatPricingUnit(property.pricingUnit))),
              ],
            ),
            if (property.size.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _detailTile(Icons.straighten_rounded, 'Size', property.size)),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textHint, letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  String _formatPricingUnit(PricingUnit unit) {
    switch (unit) {
      case PricingUnit.day: return 'Daily';
      case PricingUnit.month: return 'Monthly';
    }
  }

  // ── 7. Conditional Section (Owner, Sold, Installment) ──
  Widget _buildConditionalSection(PropertyEntity property) {
    if (_isOwner && property.listingStatus != ListingStatus.sold) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildOwnerSection(property),
      );
    }
    if (property.listingStatus == ListingStatus.sold) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
          child: Column(children: [
            ListingStatusBadge(property: property),
            const SizedBox(height: 12),
            Text(AppStrings.propertyUnavailable, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ]),
        ),
      );
    }
    if (_isForSale(property)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: InstallmentCalculator(property: property),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildOwnerSection(PropertyEntity property) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Manage Property', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        _ownerActionTile(icon: Icons.description_rounded, title: AppStrings.isArabic ? 'عرض عقود الإيجار' : 'View Leases',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaseListPage()))),
        _ownerActionTile(icon: Icons.request_quote_rounded, title: AppStrings.isArabic ? 'عرض العروض' : 'View Offers',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseRequestsPage()))),
        _ownerActionTile(icon: Icons.rocket_launch_rounded, title: AppStrings.isArabic ? 'ترويج العقار' : 'Boost Property',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SelectSellingPlanPage(propertyId: property.propertyId)))),
      ]),
    );
  }

  Widget _ownerActionTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.navyBlue.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12), onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Icon(icon, size: 20, color: AppColors.navyBlue),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary))),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Rent Calculator ──
  Widget _buildRentSection(PropertyEntity property) {
    final isDaily = property.pricingUnit == PricingUnit.day;
    final priceLabel = isDaily
        ? '${AppStrings.egp} ${_fmt(property.pricePerDay)} / ${AppStrings.day}'
        : '${AppStrings.egp} ${_fmt(property.priceValue)} / ${AppStrings.isArabic ? 'شهر' : 'mo'}';
    final durationLabel = isDaily
        ? (AppStrings.isArabic ? 'عدد الأيام' : 'Number of Days')
        : (AppStrings.isArabic ? 'عدد الأشهر' : 'Number of Months');
    final durationValue = isDaily ? _rentDays : _rentMonths;
    final maxValue = isDaily ? 90 : 12;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.calculate_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Rent Calculator', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(color: AppColors.navyBlue.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
            child: Text(priceLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navyBlue)),
          ),
          const SizedBox(height: 18),
          _buildDatePicker(),
          const SizedBox(height: 18),
          Row(children: [
            Text(durationLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const Spacer(),
            IconButton(icon: Icon(Icons.remove_circle_outline, color: durationValue > 1 ? AppColors.navyBlue : AppColors.textHint),
              onPressed: durationValue > 1 ? () => setState(() { if (isDaily) _rentDays--; else _rentMonths--; }) : null),
            Container(
              constraints: const BoxConstraints(minWidth: 36), alignment: Alignment.center,
              child: Text('$durationValue', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
            IconButton(icon: Icon(Icons.add_circle_outline, color: durationValue < maxValue ? AppColors.navyBlue : AppColors.textHint),
              onPressed: durationValue < maxValue ? () => setState(() { if (isDaily) _rentDays++; else _rentMonths++; }) : null),
          ]),
          if (_rentValid) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.navyBlue.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                _summaryRow(AppStrings.isArabic ? 'تاريخ النهاية' : 'End Date', _formatDate(_rentEndDate!)),
                const SizedBox(height: 6),
                _summaryRow(isDaily ? (AppStrings.isArabic ? 'المدة' : 'Duration') : (AppStrings.isArabic ? 'عدد الأشهر' : 'Months'),
                    isDaily ? '$_rentDays ${AppStrings.isArabic ? 'أيام' : 'days'}' : '$_rentMonths ${AppStrings.isArabic ? 'أشهر' : 'months'}'),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1, color: Color(0xFFE0E0E0))),
                _summaryRow(AppStrings.totalCost, '${AppStrings.egp} ${_fmt(_rentTotalPrice)}',
                    valueStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _rentCheckIn ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _rentCheckIn = picked);
      },
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.navyBlue.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.navyBlue.withValues(alpha: 0.15))),
        child: Row(children: [
          const Icon(Icons.calendar_today, size: 18, color: AppColors.navyBlue),
          const SizedBox(width: 10),
          Expanded(child: Text(
            _rentCheckIn != null ? _formatDate(_rentCheckIn!) : (AppStrings.isArabic ? 'اختر تاريخ البداية' : 'Select check-in date'),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _rentCheckIn != null ? AppColors.textPrimary : AppColors.textHint))),
          if (_rentCheckIn != null)
            GestureDetector(onTap: () => setState(() => _rentCheckIn = null),
              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint)),
        ]),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary.withValues(alpha: 0.8))),
      Text(value, style: valueStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]);
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  // ── 8. Map Section ──
  Widget _buildMapSection(PropertyEntity property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(AppStrings.location),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(property.latitude ?? 30.0444, property.longitude ?? 31.2357),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  if (property.latitude != null && property.longitude != null)
                    MarkerLayer(markers: [
                      Marker(point: LatLng(property.latitude!, property.longitude!), width: 40, height: 40,
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFFE53935), size: 40)),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _openGoogleMaps(property),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: Text(AppStrings.openInMaps, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            ),
          ),
        ]),
      ),
    );
  }

  // ── 9. Ratings & Reviews ──
  Widget _buildRatingsSection(PropertyEntity property) {
    final rating = property.rate ?? 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _sectionTitle(AppStrings.ratings),
            TextButton.icon(
              onPressed: () => _showAddReviewSheet(property),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Write'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: List.generate(5, (i) {
                return Icon(i < rating.round() ? Icons.star_rounded : Icons.star_border_rounded, size: 20, color: const Color(0xFFFFA000));
              })),
              const SizedBox(height: 2),
              BlocBuilder<ReviewBloc, ReviewState>(
                builder: (context, state) {
                  final count = state is ReviewsLoaded ? state.reviews.length : rating.round();
                  return Text('$count review${count == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, color: AppColors.textHint.withValues(alpha: 0.8)));
                },
              ),
            ]),
          ]),
          const SizedBox(height: 16),
          BlocBuilder<ReviewBloc, ReviewState>(
            builder: (context, state) {
              if (state is ReviewLoading) return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)));
              if (state is ReviewsLoaded && state.reviews.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: const Column(children: [
                    Icon(Icons.rate_review_outlined, size: 32, color: AppColors.textHint),
                    SizedBox(height: 8),
                    Text('No reviews yet', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text('Be the first to share your experience', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ]),
                );
              }
              if (state is ReviewsLoaded) return ReviewListWidget(reviews: state.reviews);
              return const SizedBox.shrink();
            },
          ),
        ]),
      ),
    );
  }

  void _showAddReviewSheet(PropertyEntity property) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthProfileLoaded) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddReviewSheet(
          onSubmit: (rating, phrase) {
            context.read<ReviewBloc>().add(AddReview(propertyId: property.propertyId, rating: rating, phrase: phrase));
          },
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  // ── Sticky Action Bar ──
  Widget _buildActionBar(PropertyEntity property) {
    final authState = context.read<AuthBloc>().state;
    final isAuthenticated = authState is AuthProfileLoaded;
    final ownerId = isAuthenticated ? authState.user.id : null;
    final isOwner = ownerId == property.ownerId;

    if (!isAuthenticated) {
      return Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))]),
        child: SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: const Text('Login to Contact', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    if (isOwner) {
      // Owner: show "View Leases" button to match the hierarchy
      return Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))]),
        child: SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaseListPage())),
            icon: const Icon(Icons.description_rounded, size: 20),
            label: const Text('View My Leases', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyBlue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          ),
        ),
      );
    }

    if (_isForSale(property) || property.listingStatus == ListingStatus.sold) {
      return Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))]),
        child: SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _openChat(property),
            icon: const Icon(Icons.chat_outlined, size: 20),
            label: const Text('Chat with Owner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          ),
        ),
      );
    }

    // Rent property: dual action bar
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _openChat(property),
                icon: const Icon(Icons.chat_outlined, size: 20),
                label: const Text('Chat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _sendRentRequest(property),
                icon: const Icon(Icons.home_work_outlined, size: 20),
                label: const Text('Send Rent Request', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(PropertyEntity property) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<RentRequestBloc>(),
        child: ChatDetailsPage(
          userName: _ownerDisplayName(property),
          initials: _ownerInitials(property),
          partnerId: property.ownerId,
          propertyId: property.propertyId,
        ),
      ),
    ));
  }

  void _sendRentRequest(PropertyEntity property) {
    if (!_rentValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a check-in date and duration')),
      );
      return;
    }
    String d(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    context.read<RentRequestBloc>().add(
      CreateRentRequest(
        propertyId: property.propertyId,
        checkInDate: d(_rentCheckIn!),
        checkOutDate: d(_rentEndDate!),
        rentingType: property.pricingUnit == PricingUnit.day ? 'DAY' : 'MONTH',
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
  }
}
