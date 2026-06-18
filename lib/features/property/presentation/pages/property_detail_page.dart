// lib/features/property/presentation/pages/property_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../favorite/presentation/bloc/favorite_bloc.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../widgets/property_image.dart';
import 'full_screen_image_page.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/widgets/create_rent_request_sheet.dart';
import 'package:aqar/injection_container.dart' as di;

class PropertyDetailPage extends StatefulWidget {
  final PropertyEntity property;
  const PropertyDetailPage({super.key, required this.property});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  late bool _isFavorite;
  late PageController _imagePageController;
  int _currentImageIndex = 0;
  PropertyEntity? _fullProperty;
  bool _isLoading = true;
  PricingUnit _selectedPricingUnit = PricingUnit.month;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _isFavorite = false;
    _imagePageController = PageController();
    _selectedPricingUnit = widget.property.pricingUnit;
    _quantity = 1;
    context
        .read<PropertyBloc>()
        .add(GetPropertyByIdRequested(id: widget.property.propertyId));
    context.read<FavoriteBloc>().add(GetFavoritesEvent());
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
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
    final property = _fullProperty ?? widget.property;
    final url = '${AppConfig.webUrl}/property/${property.propertyId}';
    final price = property.listingType == ListingType.forSale
        ? '\$${property.priceValue.toStringAsFixed(0)}'
        : '\$${property.priceValue.toStringAsFixed(0)}/${property.pricingUnit.label}';

    SharePlus.instance.share(
      ShareParams(
        text: '$url\n\n'
            '🏡 ${property.propertyName}\n'
            '📍 ${property.location}\n'
            '💰 $price',
      ),
    );
  }

  void _openFullScreenGallery() {
    final property = _fullProperty ?? widget.property;
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
                  content:
                      Text('Failed to load property details: ${state.message}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: _isLoading
          ? const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final property = _fullProperty ?? widget.property;
    final ownerFullName = [
      property.ownerFirstName,
      property.ownerSecondName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');
    final displayOwnerName = ownerFullName.isNotEmpty ? ownerFullName : 'Owner';

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildBottomBar(property),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageGallery(property),
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: kToolbarHeight + MediaQuery.of(context).padding.top,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              BlocListener<FavoriteBloc, FavoriteState>(
                listener: (context, state) {
                  if (state is FavoriteLoaded) {
                    final favIds =
                        state.favorites.map((p) => p.propertyId).toSet();
                    setState(() {
                      _isFavorite = favIds.contains(property.propertyId);
                    });
                  }
                },
                child: IconButton(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? const Color(0xFFD4AF37) : null,
                  ),
                ),
              ),
              IconButton(
                onPressed: _shareProperty,
                icon: const Icon(Icons.ios_share_outlined),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleAndPrice(property),
                  const SizedBox(height: 8),
                  _buildRatingOnly(property),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Property Description'),
                  const SizedBox(height: 8),
                  Text(
                    property.propertyDesc.isEmpty
                        ? 'No description available.'
                        : property.propertyDesc,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Location'),
                  const SizedBox(height: 8),
                  _buildLocationBox(property),
                  const SizedBox(height: 24),
                  _buildOwnerInfo(displayOwnerName),
                  const SizedBox(height: 24),
                  _buildDetailsTable(property),
                  if (property.listingType == ListingType.forRent) ...[
                    const SizedBox(height: 28),
                    const Divider(color: AppColors.borderLight),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Pricing Plan'),
                    const SizedBox(height: 14),
                    _buildPricingCards(property),
                    const SizedBox(height: 16),
                    _buildQuantitySelector(),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _selectedPeriodLabel(PricingUnit unit) {
    switch (unit) {
      case PricingUnit.day:
        return '/day';
      case PricingUnit.month:
        return '/mo';
      case PricingUnit.year:
        return '/yr';
    }
  }

  Widget _buildBottomBar(PropertyEntity property) {
    final bool isRent = property.listingType == ListingType.forRent;

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
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (isRent) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BlocProvider(
                          create: (_) => di.sl<RentRequestBloc>(),
                          child: CreateRentRequestSheet(
                            property: property,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isRent
                        ? 'Request to Rent'
                        : 'Book Now',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Contact Owner',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(PropertyEntity property) {
    if (property.images.isEmpty) {
      return Container(
        color: AppColors.surfaceLight,
        child: const Icon(Icons.home_outlined,
            size: 76, color: AppColors.textHint),
      );
    }

    return GestureDetector(
      onTap: _openFullScreenGallery,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _imagePageController,
            itemCount: property.images.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return PropertyImage(
                imageUrl: property.images[index],
                fit: BoxFit.cover,
                width: double.infinity,
              );
            },
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                property.images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleAndPrice(PropertyEntity property) {
    if (property.listingType == ListingType.forSale) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              property.propertyName,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${property.priceValue.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              const Text(
                'Total Price',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                property.propertyName,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Flexible pricing options',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _priceFor(PricingUnit unit, PropertyEntity property) {
    final double ppd = property.pricePerDay;
    if (ppd > 0) {
      switch (unit) {
        case PricingUnit.day:
          return ppd;
        case PricingUnit.month:
          return ppd * 30;
        case PricingUnit.year:
          return ppd * 365;
      }
    }
    switch (property.pricingUnit) {
      case PricingUnit.day:
        return unit == PricingUnit.day
            ? property.priceValue
            : unit == PricingUnit.month
                ? property.priceValue * 30
                : property.priceValue * 365;
      case PricingUnit.month:
        return unit == PricingUnit.month
            ? property.priceValue
            : unit == PricingUnit.day
                ? property.priceValue / 30
                : property.priceValue * 12;
      case PricingUnit.year:
        return unit == PricingUnit.year
            ? property.priceValue
            : unit == PricingUnit.day
                ? property.priceValue / 365
                : property.priceValue / 12;
    }
  }

  Widget _buildPricingCards(PropertyEntity property) {
    return Row(
      children: [
        Expanded(
          child: _buildPricingCard(
            'Day',
            _priceFor(PricingUnit.day, property),
            'per day',
            Icons.wb_sunny_outlined,
            _selectedPricingUnit == PricingUnit.day,
            () => setState(() {
              _selectedPricingUnit = PricingUnit.day;
              _quantity = 1;
            }),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPricingCard(
            'Monthly',
            _priceFor(PricingUnit.month, property),
            'per month',
            Icons.calendar_month_outlined,
            _selectedPricingUnit == PricingUnit.month,
            () => setState(() {
              _selectedPricingUnit = PricingUnit.month;
              _quantity = 1;
            }),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPricingCard(
            'Yearly',
            _priceFor(PricingUnit.year, property),
            'per year',
            Icons.event_outlined,
            _selectedPricingUnit == PricingUnit.year,
            () => setState(() {
              _selectedPricingUnit = PricingUnit.year;
              _quantity = 1;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(
    String label,
    double price,
    String period,
    IconData icon,
    bool isHighlighted,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlighted ? const Color(0xFFD4AF37) : AppColors.borderLight,
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isHighlighted ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isHighlighted
                  ? const Color(0xFFD4AF37)
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isHighlighted
                    ? const Color(0xFFD4AF37)
                    : AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '\$${price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isHighlighted
                    ? const Color(0xFFD4AF37)
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              period,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    final double unitPrice = _priceFor(_selectedPricingUnit, _fullProperty ?? widget.property);
    final double total = unitPrice * _quantity;
    final String unitLabel = _selectedPeriodLabel(_selectedPricingUnit);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _quantity > 1
                            ? const Color(0xFFD4AF37)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove, size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => setState(() => _quantity++),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    unitLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOnly(PropertyEntity property) {
    return Row(
      children: [
        const Icon(Icons.star, size: 18, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          property.rate?.toStringAsFixed(1) ?? '5.0',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Text(
          '(${property.bedroomsNo} beds)',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary),
    );
  }

  Widget _buildLocationBox(PropertyEntity property) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              property.location,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          if (property.latitude != null || property.longitude != null)
            Text(
              '${property.latitude?.toStringAsFixed(4) ?? "?"}, ${property.longitude?.toStringAsFixed(4) ?? "?"}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfo(String ownerName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ownerName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'Owner',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTable(PropertyEntity property) {
    final details = <String, String>{};
    details['Property Type'] = property.listingType.label;
    if (property.size.isNotEmpty) details['Size'] = property.size;
    details['Bedrooms'] = '${property.bedroomsNo}';
    details['Bathrooms'] = '${property.bathroomsNo}';
    details['Beds'] = '${property.bedsNo}';
    details['Furnished'] = property.isFurnished ? 'Yes' : 'No';
    details['Verified'] = property.isVerified ? 'Yes' : 'No';
    details['Sponsored'] = property.isSponsored ? 'Yes' : 'No';
    details['Availability'] =
        property.isAvailable ? 'Available' : 'Not Available';
    if (property.listingType == ListingType.forSale) {
      details['Price'] = '\$${property.priceValue.toStringAsFixed(0)}';
    }
    if (property.listingStatus != null) {
      details['Listing Status'] = property.listingStatus!.label;
    }
    if (property.rate != null) {
      details['Rating'] = property.rate!.toStringAsFixed(1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Details'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: details.entries.map((entry) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key,
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                    Text(entry.value,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
