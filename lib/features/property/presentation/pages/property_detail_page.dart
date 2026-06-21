import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/widgets/auth_guard.dart';
import '../../../chat/presentation/pages/chat_details_page.dart';
import '../../../favorite/presentation/bloc/favorite_bloc.dart';
import 'package:aqar/features/review/presentation/bloc/review_bloc.dart';
import 'package:aqar/features/review/presentation/widgets/add_review_sheet.dart';
import 'package:aqar/features/review/presentation/widgets/review_list_widget.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../widgets/daily_rent_calculator.dart';
import '../widgets/installment_calculator.dart';
import '../widgets/listing_status_badge.dart';
import '../widgets/owner_trust_banner.dart';
import '../widgets/property_action_bottom_sheet.dart';
import '../widgets/property_image_carousel.dart';
import 'full_screen_image_page.dart';

class PropertyDetailPage extends StatefulWidget {
  final PropertyEntity property;
  final VoidCallback? onBack;
  const PropertyDetailPage({super.key, required this.property, this.onBack});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  PropertyEntity? _fullProperty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    context
        .read<PropertyBloc>()
        .add(GetPropertyByIdRequested(id: widget.property.propertyId));
    context.read<FavoriteBloc>().add(GetFavoritesEvent());
    context
        .read<ReviewBloc>()
        .add(GetReviews(propertyId: widget.property.propertyId));
  }

  void _toggleFavorite() {
    if (_isFavorite) {
      context
          .read<FavoriteBloc>()
          .add(RemoveFavoriteEvent(widget.property.propertyId));
    } else {
      context
          .read<FavoriteBloc>()
          .add(AddFavoriteEvent(widget.property.propertyId));
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  void _shareProperty() {
    final property = _property;
    final url = '${AppConfig.webUrl}/property/${property.propertyId}';
    final price = _isForSale(property)
        ? 'EGP ${_fmt(property.priceValue)}'
        : 'EGP ${_fmt(property.priceValue)}/${property.pricingUnit.label}';
    SharePlus.instance.share(
      ShareParams(
        text: '$url\n\n${property.propertyName}\n${property.location}\n$price',
      ),
    );
  }

  void _openFullScreenGallery() {
    final property = _property;
    if (property.images.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImagePage(
          images: property.images,
          initialIndex: _currentImageIndex,
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(PropertyEntity property) async {
    final lat = property.latitude;
    final lng = property.longitude;
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  PropertyEntity get _property => _fullProperty ?? widget.property;

  bool _isForSale(PropertyEntity property) {
    return property.listingType == ListingType.forSale;
  }

  bool _isForRent(PropertyEntity property) {
    return property.listingType == ListingType.forRent;
  }

  String _ownerDisplayName(PropertyEntity property) {
    final parts = [
      property.ownerFirstName,
      property.ownerSecondName,
    ]
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
    final second = parts.length > 1
        ? parts.last.characters.first.toUpperCase()
        : '';
    return '$first$second';
  }

  bool get _isOwner {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthProfileLoaded &&
        authState.user.id == _property.ownerId;
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
              setState(() {
                _fullProperty = state.property;
                _isLoading = false;
              });
            }
            if (state is PropertyError) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.failedToLoadProperty}: ${state.message}',
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
        BlocListener<FavoriteBloc, FavoriteState>(
          listener: (context, state) {
            if (state is FavoriteLoaded) {
              final favIds =
                  state.favorites.map((p) => p.propertyId).toSet();
              setState(() {
                _isFavorite = favIds.contains(_property.propertyId);
              });
            }
          },
        ),
      ],
      child: _isLoading
          ? const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final property = _property;
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildActionBar(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              PropertyImageCarousel(
                images: property.images,
                currentIndex: _currentImageIndex,
                onIndexChanged: (i) => _currentImageIndex = i,
                onTap: _openFullScreenGallery,
              ),
              SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceAndStatus(property),
                  const SizedBox(height: 12),
                  OwnerTrustBanner(property: property),
                  const SizedBox(height: 12),
                  _buildTitleAndLocation(property),
                  const SizedBox(height: 10),
                  _buildFeatureGrid(property),
                  const SizedBox(height: 20),
                  _buildConditionalSection(property),
                  const SizedBox(height: 20),
                  _buildAboutSection(property),
                  const SizedBox(height: 20),
                  _buildLocationSection(property),
                  const SizedBox(height: 20),
                  _buildInfoTable(property),
                  const SizedBox(height: 24),
                  _buildRatingsSection(property),
                ],
              ),
            ),
          ),
        ],
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              widget.onBack?.call();
              if (widget.onBack == null) {
                Navigator.pop(context);
              }
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
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: _isFavorite
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _shareProperty,
                icon: const Icon(Icons.ios_share_outlined),
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ],
    ),
  );
}

  Widget _buildPriceAndStatus(PropertyEntity property) {
    final isSold = property.listingStatus == ListingStatus.sold;
    String priceText;
    if (_isForSale(property)) {
      priceText = '${AppStrings.egp} ${_fmt(property.priceValue)}';
    } else if (property.pricingUnit == PricingUnit.day) {
      priceText =
          '${AppStrings.egp} ${_fmt(property.priceValue)} ${AppStrings.perDay}';
    } else {
      priceText =
          '${AppStrings.egp} ${_fmt(property.priceValue)} ${AppStrings.perMonth}';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            priceText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        if (isSold)
          ListingStatusBadge(property: property)
        else
          ListingStatusBadge(property: property),
      ],
    );
  }

  Widget _buildTitleAndLocation(PropertyEntity property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          property.propertyName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.location_on_rounded,
                size: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                property.location,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(PropertyEntity property) {
    final features = [
      (Icons.bed_rounded, '${property.bedroomsNo} ${AppStrings.bedrooms}'),
      (Icons.bathtub_rounded,
          '${property.bathroomsNo} ${AppStrings.bathrooms}'),
      (Icons.square_foot_rounded,
          property.size.isNotEmpty ? property.size : '—'),
      (Icons.king_bed_rounded, '${property.bedsNo} ${AppStrings.beds}'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.map((f) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(f.$1, size: 16, color: AppColors.navyBlue),
              const SizedBox(width: 5),
              Text(
                f.$2,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConditionalSection(PropertyEntity property) {
    if (property.listingStatus == ListingStatus.sold) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          children: [
            ListingStatusBadge(property: property),
            const SizedBox(height: 12),
            Text(
              AppStrings.propertyUnavailable,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_isForSale(property)) {
      return InstallmentCalculator(property: property);
    }

    if (_isForRent(property) && property.pricingUnit == PricingUnit.day) {
      return DailyRentCalculator(property: property);
    }

    return _buildMonthlyRentCard(property);
  }

  Widget _buildMonthlyRentCard(PropertyEntity property) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.navyBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_rounded,
                    size: 20, color: AppColors.navyBlue),
                const SizedBox(width: 10),
                Text(
                  '${AppStrings.monthlyRent}: ${AppStrings.egp} ${_fmt(property.priceValue)} ${AppStrings.perMonth}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => requireVerifiedUser(
                context,
                onAllowed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailsPage(
                        userName: _ownerDisplayName(property),
                        initials: _ownerInitials(property),
                        partnerId: property.ownerId,
                        propertyId: property.propertyId,
                      ),
                    ),
                  );
                },
              ),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: Text(
                AppStrings.sendRentRequest,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(PropertyEntity property) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(AppStrings.aboutProperty),
          const SizedBox(height: 10),
          Text(
            property.propertyDesc.isEmpty
                ? AppStrings.noDescription
                : property.propertyDesc,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(PropertyEntity property) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(AppStrings.location),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppColors.navyBlue,
                  AppColors.navyBlue.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.map_rounded,
                size: 48,
                color: Colors.white.withValues(alpha: 0.4),
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
              label: Text(
                AppStrings.openInMaps,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTable(PropertyEntity property) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(AppStrings.propertyInfo),
          const SizedBox(height: 14),
          _infoRow(
              AppStrings.type, _isForSale(property)
                  ? AppStrings.forSale
                  : AppStrings.forRent),
          _infoDivider(),
          _infoRow(AppStrings.furnished,
              property.isFurnished ? AppStrings.yes : AppStrings.no),
          _infoDivider(),
          _infoRow(
            AppStrings.verified,
            null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: property.isVerified
                      ? AppColors.success
                      : AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  property.isVerified
                      ? AppStrings.verified
                      : AppStrings.notVerified,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: property.isVerified
                        ? AppColors.success
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          _infoDivider(),
          _infoRow(
            AppStrings.pricing,
            _isForSale(property)
                ? AppStrings.fixedPrice
                : _formatPricingUnit(property.pricingUnit),
          ),
          if (property.size.isNotEmpty) ...[
            _infoDivider(),
            _infoRow(AppStrings.size, property.size),
          ],
        ],
      ),
    );
  }

  String _formatPricingUnit(PricingUnit unit) {
    switch (unit) {
      case PricingUnit.day:
        return AppStrings.isArabic ? 'يومي' : 'Daily';
      case PricingUnit.month:
        return AppStrings.isArabic ? 'شهري' : 'Monthly';
      case PricingUnit.year:
        return AppStrings.isArabic ? 'سنوي' : 'Yearly';
    }
  }

  Widget _infoRow(String label, String? value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
          trailing ??
              Text(
                value ?? '—',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
        ],
      ),
    );
  }

  Widget _infoDivider() {
    return Divider(height: 1, color: const Color(0xFFF0F0F0));
  }

  Widget _buildRatingsSection(PropertyEntity property) {
    final rating = property.rate ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle(AppStrings.ratings),
              TextButton.icon(
                onPressed: () => _showAddReviewSheet(property),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Write'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < rating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 20,
                        color: const Color(0xFFFFA000),
                      );
                    }),
                  ),
                  const SizedBox(height: 2),
                  BlocBuilder<ReviewBloc, ReviewState>(
                    builder: (context, state) {
                      final count = state is ReviewsLoaded
                          ? state.reviews.length
                          : rating.round();
                      return Text(
                        '$count review${count == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint.withValues(alpha: 0.8),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<ReviewBloc, ReviewState>(
            builder: (context, state) {
              if (state is ReviewLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              final reviews = state is ReviewsLoaded ? state.reviews : <dynamic>[];
              return ReviewListWidget(reviews: reviews.cast());
            },
          ),
        ],
      ),
    );
  }

  void _showAddReviewSheet(PropertyEntity property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddReviewSheet(
        onSubmit: (rating, phrase) {
          context.read<ReviewBloc>().add(
                AddReview(
                  rating: rating,
                  phrase: phrase,
                  propertyId: property.propertyId,
                ),
              );
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildActionBar() {
    final authState = context.read<AuthBloc>().state;
    final property = _property;

    if (authState is! AuthProfileLoaded) {
      return _singleButton(
        AppStrings.loginToContact,
        Icons.login_rounded,
        () => Navigator.pushNamed(context, '/auth'),
      );
    }

    if (_isOwner) {
      return _singleButton(
        AppStrings.editProperty,
        Icons.edit_rounded,
        () => showPropertyActionSheet(context, property),
      );
    }

    return _singleButton(
      AppStrings.chat,
      Icons.chat_rounded,
      () => requireVerifiedUser(
        context,
        onAllowed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailsPage(
                userName: _ownerDisplayName(property),
                initials: _ownerInitials(property),
                partnerId: property.ownerId,
                propertyId: property.propertyId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _singleButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}
