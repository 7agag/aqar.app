import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/extensions/num_formatting.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
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
import '../../../lease/presentation/bloc/lease_bloc.dart';
import '../../../lease/presentation/bloc/lease_event.dart';
import '../../../lease/presentation/bloc/lease_state.dart';
import '../../../lease/domain/entities/lease_entity.dart';
import '../../../purchase_request/presentation/bloc/purchase_request_bloc.dart';
import 'package:aqar/features/sponsor/presentation/pages/sponsorship_page.dart';
import '../widgets/listing_status_badge.dart';
import '../widgets/owner_trust_banner.dart';
import '../widgets/property_image_carousel.dart';
import '../widgets/recommended_properties_row.dart';
import 'full_screen_image_page.dart';
import 'selling_plan_page.dart';
import '../../../../core/services/biometric_auth_guard.dart';
import '../../../../injection_container.dart' as di;

class PropertyDetailPage extends StatefulWidget {
  final int propertyId;
  final VoidCallback? onBack;
  const PropertyDetailPage({super.key, required this.propertyId, this.onBack});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  bool _isFavorite = false;
  bool _revertFavTo = false;
  bool _favLoading = false;
  Set<int> _favoriteIds = {};
  int _currentImageIndex = 0;
  late PageController _pageController;
  PropertyEntity? _property;
  bool _isLoading = true;
  DateTime? _rentCheckIn;
  int _rentDays = 1;
  int _rentMonths = 1;
  bool _aboutExpanded = false;
  PropertyContext _context = PropertyContext.visitor;
  LeaseEntity? _activeLease;
  late final LeaseBloc _leaseBloc;
  StreamSubscription? _leaseSub;

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
    _pageController = PageController();
    _leaseBloc = di.sl<LeaseBloc>();
    _leaseSub = _leaseBloc.stream.listen(_onLeaseState);
    context
        .read<PropertyBloc>()
        .add(GetPropertyByIdRequested(id: widget.propertyId));
    context.read<FavoriteBloc>().add(GetFavoritesEvent());
    context.read<ReviewBloc>().add(GetReviews(propertyId: widget.propertyId));
  }

  @override
  void didUpdateWidget(covariant PropertyDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.propertyId != widget.propertyId) {
      _pageController.jumpToPage(0);
      setState(() {
        _isLoading = true;
        _property = null;
        _isFavorite = false;
        _currentImageIndex = 0;
        _aboutExpanded = false;
        _rentCheckIn = null;
        _rentDays = 1;
        _rentMonths = 1;
      });
      context
          .read<PropertyBloc>()
          .add(GetPropertyByIdRequested(id: widget.propertyId));
      context.read<FavoriteBloc>().add(GetFavoritesEvent());
      context.read<ReviewBloc>().add(GetReviews(propertyId: widget.propertyId));
    }
  }

  @override
  void dispose() {
    _leaseSub?.cancel();
    _leaseBloc.close();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    if (_favLoading) return;
    _revertFavTo = _isFavorite;
    _favLoading = true;
    setState(() => _isFavorite = !_isFavorite);
    if (_revertFavTo) {
      context.read<FavoriteBloc>().add(RemoveFavoriteEvent(widget.propertyId));
    } else {
      context.read<FavoriteBloc>().add(AddFavoriteEvent(widget.propertyId));
    }
  }

  void _shareProperty() {
    final property = _property!;
    final url = '${AppConfig.webUrl}/property/${property.propertyId}';
    final price = _isForSale(property)
        ? '${AppStrings.egp} ${property.priceValue.formatWithCommas()}'
        : '${AppStrings.egp} ${property.priceValue.formatWithCommas()}/${property.pricingUnit.label}';
    final text =
        '$url\n\n${property.propertyName}\n${property.location}\n$price';

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
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Share Property',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareOption(ctx,
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366), onTap: () {
                    Navigator.pop(ctx);
                    _shareWhatsApp(text);
                  }),
                  _shareOption(ctx,
                      icon: Icons.copy_rounded,
                      label: 'Copy Link',
                      color: AppColors.navyBlue, onTap: () {
                    Navigator.pop(ctx);
                    _copyLink(url);
                  }),
                  _shareOption(ctx,
                      icon: Icons.share_rounded,
                      label: 'More',
                      color: AppColors.primary, onTap: () {
                    Navigator.pop(ctx);
                    _shareSystem(text);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareOption(BuildContext ctx,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26)),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Link copied to clipboard'),
          duration: Duration(seconds: 2)));
    }
  }

  void _shareSystem(String text) {
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _openFullScreenGallery() {
    final property = _property!;
    if (property.images.isEmpty) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FullScreenImagePage(
                images: property.images, initialIndex: _currentImageIndex)));
  }

  Future<void> _openGoogleMaps(PropertyEntity property) async {
    final lat = property.latitude;
    final lng = property.longitude;
    if (lat == null || lng == null) return;
    final geoUri = Uri.parse('geo:0,0?q=$lat,$lng');
    final webUri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  bool _isForSale(PropertyEntity property) =>
      property.listingType == ListingType.forSale;

  String _ownerDisplayName(PropertyEntity property) {
    final parts = [property.ownerFirstName, property.ownerSecondName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Property Owner';
    return parts.join(' ');
  }

  String _ownerInitials(PropertyEntity property) {
    final parts = _ownerDisplayName(property)
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'PO';
    final first = parts.first.characters.first.toUpperCase();
    final second =
        parts.length > 1 ? parts.last.characters.first.toUpperCase() : '';
    return '$first$second';
  }

  bool get _isOwner {
    final authState = context.read<AuthBloc>().state;
    if (_property == null) return false;
    final user = switch (authState) {
      AuthProfileLoaded(:final user) => user,
      AuthProfileUpdateSuccess(:final user) => user,
      _ => null,
    };
    if (user == null) return false;
    return user.id.trim().toString() == _property!.ownerId.trim().toString();
  }

  void _determineContext() {
    if (_property == null) return;
    setState(() {
      _context = PropertyContext.visitor;
      _activeLease = null;
    });
    if (_isOwner) {
      setState(() => _context = PropertyContext.owner);
      _leaseBloc.add(const GetOwnerLeasesRequested());
    } else {
      _leaseBloc.add(const GetRenterLeasesRequested());
    }
  }

  void _onLeaseState(LeaseState state) {
    if (!mounted) return;
    if (state is OwnerLeasesLoaded && _context == PropertyContext.owner) {
      final match = state.leases
          .where((l) => l.propertyId == _property?.propertyId)
          .firstOrNull;
      if (match != null) setState(() => _activeLease = match);
    }
    if (state is RenterLeasesLoaded && _context != PropertyContext.owner) {
      final match = state.leases
          .where((l) => l.propertyId == _property?.propertyId)
          .firstOrNull;
      if (match != null) {
        setState(() {
          _context = PropertyContext.renter;
          _activeLease = match;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PropertyBloc, PropertyState>(
          listener: (context, state) {
            if (state is PropertyDetailLoaded) {
              setState(() {
                _property = state.property;
                _isLoading = false;
                _isFavorite = _favoriteIds.contains(state.property.propertyId);
              });
              _determineContext();
            }
            if (state is PropertyError) setState(() => _isLoading = false);
            if (state is PropertyDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.success),
              );
              Navigator.pop(context);
            }
          },
        ),
        BlocListener<FavoriteBloc, FavoriteState>(
          listener: (context, state) {
            if (_property == null) return;
            if (state is FavoriteLoading) {
              setState(() => _favLoading = true);
            }
            if (state is FavoriteLoaded) {
              _favLoading = false;
              _favoriteIds = state.favorites.map((p) => p.propertyId).toSet();
              if (_property != null) {
                setState(() {
                  _isFavorite = _favoriteIds.contains(_property!.propertyId);
                });
              }
            }
            if (state is FavoriteError) {
              _favLoading = false;
              setState(() {
                _isFavorite = _revertFavTo;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error),
              );
            }
          },
        ),
        BlocListener<RentRequestBloc, RentRequestState>(
          listener: (context, state) {
            if (state is RentRequestActionSuccess) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
              setState(() {
                _rentCheckIn = null;
                _rentDays = 1;
                _rentMonths = 1;
              });
            }
            if (state is RentRequestError) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
        BlocListener<PurchaseRequestBloc, PurchaseRequestState>(
          listener: (context, state) {
            if (state is PurchaseRequestSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.success),
              );
              context
                  .read<PropertyBloc>()
                  .add(GetPropertyByIdRequested(id: widget.propertyId));
            }
            if (state is PurchaseRequestError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error),
              );
            }
          },
        ),
        BlocListener<ReviewBloc, ReviewState>(
          listener: (context, state) {
            if (state is ReviewAdded) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.success),
              );
              context
                  .read<ReviewBloc>()
                  .add(GetReviews(propertyId: widget.propertyId));
            }
            if (state is ReviewError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error),
              );
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (_, current) => current is AuthProfileLoaded,
          listener: (context, state) {
            if (_property != null) {
              _determineContext();
            }
          },
        ),
      ],
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
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
                Icon(Icons.error_outline_rounded,
                    size: 72, color: AppColors.textHint.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('Could not load property',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context
                      .read<PropertyBloc>()
                      .add(GetPropertyByIdRequested(id: widget.propertyId)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white)),
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
          RefreshIndicator(
            onRefresh: () async {
              context
                  .read<PropertyBloc>()
                  .add(GetPropertyByIdRequested(id: widget.propertyId));
              context.read<FavoriteBloc>().add(GetFavoritesEvent());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── 1. Header Gallery ──
                PropertyImageCarousel(
                  images: property.images,
                  currentIndex: _currentImageIndex,
                  onIndexChanged: (i) => setState(() => _currentImageIndex = i),
                  onTap: _openFullScreenGallery,
                  pageController: _pageController,
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
                      if (property.listingType == ListingType.forRent &&
                          !_isOwner &&
                          _context != PropertyContext.renter &&
                          property.listingStatus != ListingStatus.sold) ...[
                        const SizedBox(height: 16),
                        _buildRentSection(property),
                      ],
                      const SizedBox(height: 16),
                      // ── 8. Location on Map ──
                      _buildMapSection(property),
                      const SizedBox(height: 16),
                      // ── 9. Ratings & Reviews ──
                      _buildRatingsSection(property),
                      const SizedBox(height: 16),
                      _buildRecommendedProperties(property),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Overlay Buttons ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle),
              child: IconButton(
                onPressed: () {
                  widget.onBack?.call();
                  if (widget.onBack == null) Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textPrimary,
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
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: _favLoading ? null : _toggleFavorite,
                    icon: _favLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite
                                ? AppColors.primary
                                : AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle),
                  child: IconButton(
                      onPressed: _shareProperty,
                      icon: const Icon(Icons.ios_share_outlined),
                      color: AppColors.textPrimary),
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
    String priceText;
    if (_isForSale(property)) {
      priceText = '${AppStrings.egp} ${property.priceValue.formatWithCommas()}';
    } else if (property.pricingUnit == PricingUnit.day) {
      priceText =
          '${AppStrings.egp} ${property.priceValue.formatWithCommas()} ${AppStrings.perDay}';
    } else {
      priceText =
          '${AppStrings.egp} ${property.priceValue.formatWithCommas()} ${AppStrings.perMonth}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  property.propertyName,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2),
                ),
              ),
              Text(priceText,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ],
          ),
          OwnerTrustBanner(property: property),
        ],
      ),
    );
  }

  Widget _buildLocation(PropertyEntity property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _openGoogleMaps(property),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE))),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_on_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(property.location,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
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
          _specCard(
              Icons.bathtub_rounded, '${property.bathroomsNo}', 'Bathrooms'),
          const SizedBox(width: 10),
          _specCard(
              Icons.square_foot_rounded,
              property.size.isNotEmpty
                  ? property.size.replaceAll(RegExp(r'[^0-9.]'), '')
                  : '—',
              'Area'),
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
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.navyBlue),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textHint)),
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
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Property Details'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _detailTile(
                        Icons.home_work_outlined,
                        'Type',
                        property.listingType == ListingType.forSale
                            ? 'For Sale'
                            : 'For Rent')),
                Expanded(
                    child: _detailTile(Icons.weekend_outlined, 'Furnished',
                        property.isFurnished ? 'Yes' : 'No')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _detailTile(Icons.verified_outlined, 'Verified',
                        property.isVerified ? 'Verified' : 'Not Verified')),
                Expanded(
                    child: _detailTile(Icons.attach_money_rounded, 'Pricing',
                        _formatPricingUnit(property.pricingUnit))),
              ],
            ),
            if (property.size.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _detailTile(
                          Icons.straighten_rounded, 'Size', property.size)),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                    letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  String _formatPricingUnit(PricingUnit unit) {
    return switch (unit) {
      PricingUnit.day => 'Daily',
      PricingUnit.month => 'Monthly',
    };
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
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.aboutProperty),
            const SizedBox(height: 10),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _aboutExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(desc,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textSecondary)),
              secondChild: Text(desc,
                  style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textSecondary)),
            ),
            if (needsToggle)
              GestureDetector(
                onTap: () => setState(() => _aboutExpanded = !_aboutExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _aboutExpanded ? 'Show less' : 'Read more',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── 6. Property Details Grid ──
  Widget _buildConditionalSection(PropertyEntity property) {
    if (_isOwner) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildOwnerSection(property),
      );
    }
    if (property.listingStatus == ListingStatus.sold) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE))),
          child: Column(children: [
            ListingStatusBadge(property: property),
            const SizedBox(height: 12),
            Text(AppStrings.propertyUnavailable,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textSecondary)),
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
    final isSale = property.listingType == ListingType.forSale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Manage Property',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        if (isSale) ...[
          if (property.listingStatus == ListingStatus.inactive &&
              property.isVerified) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Subscription Missing',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.error)),
                        const SizedBox(height: 2),
                        Text('Selling plan not found. Tap to manage.',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SellingPlanPage(
                                propertyId: property.propertyId))),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_right,
                          color: AppColors.error, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildManageTile(
              icon: Icons.payments_outlined,
              title: AppStrings.isArabic
                  ? 'إدارة خطة البيع'
                  : 'Manage Selling Plan',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          SellingPlanPage(propertyId: property.propertyId)))),
          _buildManageTile(
              icon: Icons.rocket_launch_rounded,
              title: AppStrings.isArabic ? 'ترويج العقار' : 'Boost Property',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          SponsorshipPage(propertyId: property.propertyId)))),
          if (property.listingStatus != ListingStatus.sold) ...[
            _buildManageTile(
                icon: Icons.check_circle_outline,
                title: AppStrings.isArabic ? 'وضع كمباع' : 'Mark as Sold',
                onTap: () => _confirmMarkAsSold(property)),
          ],
          _buildManageTile(
              icon: Icons.delete_outline_rounded,
              title: AppStrings.isArabic ? 'حذف العقار' : 'Delete Property',
              isDestructive: true,
              onTap: () => _confirmDeleteProperty(property)),
        ] else ...[
          _buildManageTile(
              icon: Icons.description_rounded,
              title: AppStrings.isArabic ? 'عرض عقود الإيجار' : 'View Leases',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LeaseListPage()))),
          _buildManageTile(
              icon: Icons.rocket_launch_rounded,
              title: AppStrings.isArabic ? 'ترويج العقار' : 'Boost Property',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          SponsorshipPage(propertyId: property.propertyId)))),
        ],
      ]),
    );
  }

  void _confirmMarkAsSold(PropertyEntity property) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Sold'),
        content: Text(
            'Mark "${property.propertyName}" as sold? This will hide it from search results.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<PurchaseRequestBloc>()
                  .add(MarkPropertySold(propertyId: property.propertyId));
            },
            child: const Text('Mark as Sold',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProperty(PropertyEntity property) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text(
            'Are you sure you want to delete "${property.propertyName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final pageContext = context;
              Navigator.pop(ctx);
              final ok = await BiometricAuthGuard.guard(
                pageContext,
                reason: 'Verify your identity to delete this property',
              );
              if (!ok || !pageContext.mounted) return;
              pageContext
                  .read<PropertyBloc>()
                  .add(DeletePropertyRequested(id: property.propertyId));
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildManageTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool isDestructive = false}) {
    final color = isDestructive ? AppColors.error : AppColors.navyBlue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDestructive
                            ? AppColors.error
                            : AppColors.textPrimary)),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 22,
                  color: isDestructive
                      ? AppColors.error.withValues(alpha: 0.5)
                      : AppColors.textHint),
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
        ? '${AppStrings.egp} ${property.pricePerDay.formatWithCommas()} / ${AppStrings.day}'
        : '${AppStrings.egp} ${property.priceValue.formatWithCommas()} / ${AppStrings.isArabic ? 'شهر' : 'mo'}';
    final durationLabel = isDaily
        ? (AppStrings.isArabic ? 'عدد الأيام' : 'Number of Days')
        : (AppStrings.isArabic ? 'عدد الأشهر' : 'Number of Months');
    final durationValue = isDaily ? _rentDays : _rentMonths;
    final maxValue = isDaily ? 90 : 12;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.calculate_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Rent Calculator',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
                color: AppColors.navyBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10)),
            child: Text(priceLabel,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyBlue)),
          ),
          const SizedBox(height: 18),
          _buildDatePicker(),
          const SizedBox(height: 18),
          Row(children: [
            Text(durationLabel,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Spacer(),
            IconButton(
                icon: Icon(Icons.remove_circle_outline,
                    color: durationValue > 1
                        ? AppColors.navyBlue
                        : AppColors.textHint),
                onPressed: durationValue > 1
                    ? () => setState(() {
                          if (isDaily) {
                            _rentDays--;
                          } else {
                            _rentMonths--;
                          }
                        })
                    : null),
            Container(
                constraints: const BoxConstraints(minWidth: 36),
                alignment: Alignment.center,
                child: Text('$durationValue',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary))),
            IconButton(
                icon: Icon(Icons.add_circle_outline,
                    color: durationValue < maxValue
                        ? AppColors.navyBlue
                        : AppColors.textHint),
                onPressed: durationValue < maxValue
                    ? () => setState(() {
                          if (isDaily) {
                            _rentDays++;
                          } else {
                            _rentMonths++;
                          }
                        })
                    : null),
          ]),
          if (_rentValid) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.navyBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                _summaryRow(AppStrings.isArabic ? 'تاريخ النهاية' : 'End Date',
                    _formatDate(_rentEndDate!)),
                const SizedBox(height: 6),
                _summaryRow(
                    isDaily
                        ? (AppStrings.isArabic ? 'المدة' : 'Duration')
                        : (AppStrings.isArabic ? 'عدد الأشهر' : 'Months'),
                    isDaily
                        ? '$_rentDays ${AppStrings.isArabic ? 'أيام' : 'days'}'
                        : '$_rentMonths ${AppStrings.isArabic ? 'أشهر' : 'months'}'),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(height: 1, color: Color(0xFFE0E0E0))),
                _summaryRow(AppStrings.totalCost,
                    '${AppStrings.egp} ${_rentTotalPrice.formatWithCommas()}',
                    valueStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
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
          initialDate:
              _rentCheckIn ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _rentCheckIn = picked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: AppColors.navyBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.navyBlue.withValues(alpha: 0.15))),
        child: Row(children: [
          const Icon(Icons.calendar_today, size: 18, color: AppColors.navyBlue),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  _rentCheckIn != null
                      ? _formatDate(_rentCheckIn!)
                      : (AppStrings.isArabic
                          ? 'اختر تاريخ البداية'
                          : 'Select check-in date'),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _rentCheckIn != null
                          ? AppColors.textPrimary
                          : AppColors.textHint))),
          if (_rentCheckIn != null)
            GestureDetector(
                onTap: () => setState(() => _rentCheckIn = null),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textHint)),
        ]),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.8))),
      Text(value,
          style: valueStyle ??
              const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
    ]);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // ── 8. Map Section ──
  Widget _buildMapSection(PropertyEntity property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(AppStrings.location),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                key: ValueKey(property.propertyId),
                options: MapOptions(
                  initialCenter: LatLng(property.latitude ?? 30.0444,
                      property.longitude ?? 31.2357),
                  initialZoom: 15,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    userAgentPackageName: 'com.aqar.app',
                  ),
                  if (property.latitude != null && property.longitude != null)
                    MarkerLayer(markers: [
                      Marker(
                          point:
                              LatLng(property.latitude!, property.longitude!),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on_rounded,
                              color: Color(0xFFE53935), size: 40)),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _openGoogleMaps(property),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: Text(AppStrings.openInMaps,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0),
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
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _sectionTitle(AppStrings.ratings),
            TextButton.icon(
              onPressed: () => _showAddReviewSheet(property),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Write'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Text(rating.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                  children: List.generate(5, (i) {
                return Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 20,
                    color: const Color(0xFFFFA000));
              })),
              const SizedBox(height: 2),
              BlocBuilder<ReviewBloc, ReviewState>(
                builder: (context, state) {
                  final count = state is ReviewsLoaded
                      ? state.reviews.length
                      : rating.round();
                  return Text('$count review${count == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint.withValues(alpha: 0.8)));
                },
              ),
            ]),
          ]),
          const SizedBox(height: 16),
          BlocBuilder<ReviewBloc, ReviewState>(
            builder: (context, state) {
              if (state is ReviewLoading) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2)));
              }
              if (state is ReviewsLoaded && state.reviews.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: const Column(children: [
                    Icon(Icons.rate_review_outlined,
                        size: 32, color: AppColors.textHint),
                    SizedBox(height: 8),
                    Text('No reviews yet',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    Text('Be the first to share your experience',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ]),
                );
              }
              if (state is ReviewsLoaded) {
                return ReviewListWidget(reviews: state.reviews);
              }
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
            context.read<ReviewBloc>().add(AddReview(
                propertyId: property.propertyId,
                rating: rating,
                phrase: phrase));
          },
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  Widget _buildRecommendedProperties(PropertyEntity property) {
    return RecommendedPropertiesRow(
      propertyId: property.propertyId,
      propertyDescription: property.propertyDesc,
    );
  }

  // ── Sticky Action Bar ──
  Widget _buildLeaseBanner() {
    final lease = _activeLease;
    if (lease == null) return const SizedBox.shrink();
    final title = _context == PropertyContext.owner
        ? 'Upcoming Lease'
        : 'Your Lease is Confirmed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_rounded,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                    'From ${_formatDate(lease.checkInDate)} to ${_formatDate(lease.checkOutDate)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(PropertyEntity property) {
    final authState = context.read<AuthBloc>().state;
    final isAuthenticated = authState is AuthProfileLoaded;

    if (!isAuthenticated) {
      return Container(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ]),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0),
            child: const Text('Login to Contact',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    switch (_context) {
      case PropertyContext.owner:
        return _buildOwnerActionBar(property);
      case PropertyContext.renter:
        return _buildLeasedActionBar(property, isRenter: true);
      case PropertyContext.visitor:
        if (_isForSale(property) ||
            property.listingStatus == ListingStatus.sold) {
          return Container(
            padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2))
            ]),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _openChatWith(
                    partnerId: property.ownerId,
                    userName: _ownerDisplayName(property),
                    initials: _ownerInitials(property)),
                icon: const Icon(Icons.chat_outlined, size: 20),
                label: const Text('Chat with Owner',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
              ),
            ),
          );
        }
        return Container(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -2))
          ]),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _openChatWith(
                        partnerId: property.ownerId,
                        userName: _ownerDisplayName(property),
                        initials: _ownerInitials(property)),
                    icon: const Icon(Icons.chat_outlined, size: 20),
                    label: const Text('Chat',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
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
                    label: const Text('Send Rent Request',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildOwnerActionBar(PropertyEntity property) {
    if (property.listingType == ListingType.forSale) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2))
      ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_activeLease != null) _buildLeaseBanner(),
          if (_activeLease != null)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _openChatWith(
                        partnerId: _activeLease!.renterId,
                        userName: _activeLease!.renterName ?? 'Renter',
                        initials: _activeLease!.renterName != null &&
                                _activeLease!.renterName!.isNotEmpty
                            ? _activeLease!.renterName!
                                .split(' ')
                                .map((s) =>
                                    s.isNotEmpty ? s[0].toUpperCase() : '')
                                .take(2)
                                .join()
                            : 'RN',
                      ),
                      icon: const Icon(Icons.chat_outlined, size: 20),
                      label: const Text('Message the Renter',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LeaseListPage())),
                      icon: const Icon(Icons.description_rounded, size: 20),
                      label: const Text('View Leases',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LeaseListPage())),
                icon: const Icon(Icons.description_rounded, size: 20),
                label: const Text('View My Leases',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeasedActionBar(PropertyEntity property,
      {required bool isRenter}) {
    final partnerId =
        isRenter ? property.ownerId : (_activeLease?.renterId ?? '');
    final userName = isRenter
        ? _ownerDisplayName(property)
        : (_activeLease?.renterName ?? 'Renter');
    final initials = isRenter ? _ownerInitials(property) : 'RN';

    return Container(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2))
      ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLeaseBanner(),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _openChatWith(
                        partnerId: partnerId,
                        userName: userName,
                        initials: initials),
                    icon: const Icon(Icons.chat_outlined, size: 20),
                    label: Text(
                        isRenter ? 'Message the Owner' : 'Message the Renter',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LeaseListPage())),
                    icon: const Icon(Icons.description_rounded, size: 20),
                    label: const Text('View Leases',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openChatWith(
      {required String partnerId,
      required String userName,
      required String initials}) {
    final property = _property;
    if (property == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<RentRequestBloc>(),
            child: ChatDetailsPage(
              userName: userName,
              initials: initials,
              partnerId: partnerId,
              propertyId: property.propertyId,
              propertyName: property.propertyName,
              propertyPrice: property.priceValue,
              isSaleProperty: property.listingType == ListingType.forSale,
            ),
          ),
        ));
  }

  void _sendRentRequest(PropertyEntity property) {
    if (!_rentValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a check-in date and duration')),
      );
      return;
    }
    String d(DateTime dt) =>
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    context.read<RentRequestBloc>().add(
          CreateRentRequest(
            propertyId: property.propertyId,
            checkInDate: d(_rentCheckIn!),
            checkOutDate: d(_rentEndDate!),
            rentingType:
                property.pricingUnit == PricingUnit.day ? 'DAY' : 'MONTH',
          ),
        );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary));
  }
}
