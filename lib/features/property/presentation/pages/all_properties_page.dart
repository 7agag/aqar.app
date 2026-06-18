// lib/features/property/presentation/pages/all_properties_page.dart

import 'package:aqar/features/property/presentation/pages/property_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/refreshable_widget.dart';
import '../../../favorite/presentation/bloc/favorite_bloc.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';
import '../../domain/entities/property_filter_params.dart';
import '../bloc/property_bloc.dart';
import '../widgets/sponsored_property_card.dart';

enum PageType { sale, rent }

class AllPropertiesPage extends StatefulWidget {
  final PageType pageType;
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final int? bedrooms;
  final int? bathrooms;
  const AllPropertiesPage({
    super.key,
    required this.pageType,
    this.location,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.bathrooms,
  });

  @override
  State<AllPropertiesPage> createState() => _AllPropertiesPageState();
}

class _AllPropertiesPageState extends State<AllPropertiesPage> {
  List<PropertyEntity> _filteredProperties = [];
  bool _isLoading = true;

  Set<int> _favoriteIds = {};

  String get _title {
    switch (widget.pageType) {
      case PageType.sale:
        return 'Properties For Sale';
      case PageType.rent:
        return 'Properties For Rent';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _loadFavorites();
  }

  void _loadFavorites() {
    context.read<FavoriteBloc>().add(GetFavoritesEvent());
  }

  void _applyLocalFilter(List<PropertyEntity> allProperties) {
    setState(() {
      _filteredProperties = allProperties
          .where((p) => p.listingType == (widget.pageType == PageType.sale ? ListingType.forSale : ListingType.forRent))
          .toList();
    });
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    final params = PropertyFilterParams(
      location: widget.location,
      minPrice: widget.minPrice,
      maxPrice: widget.maxPrice,
      bedrooms: widget.bedrooms,
      bathrooms: widget.bathrooms,
    );
    final result =
        await context.read<PropertyBloc>().getPropertiesDirectly(params);
    result.fold(
      (failure) {
        setState(() => _isLoading = false);
      },
      (properties) {
        _applyLocalFilter(properties);
        setState(() => _isLoading = false);
      },
    );
  }

  Future<void> _onRefresh() async {
    _filteredProperties.clear();
    setState(() => _isLoading = true);
    await _loadProperties();
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
        ),
        title: Text(
          _title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<FavoriteBloc, FavoriteState>(
            listener: (context, state) {
              if (state is FavoriteLoaded) {
                _favoriteIds = state.favorites.map((p) => p.propertyId).toSet();
              } else if (state is FavoriteOperationSuccess) {
                _loadFavorites();
              }
            },
          ),
        ],
        child: RefreshableWidget(
          onRefresh: _onRefresh,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _filteredProperties.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_filteredProperties.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No sponsored properties found',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredProperties.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredProperties.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          final property = _filteredProperties[index];
          return SponsoredPropertyCard(
            property: property,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailPage(property: property),
              ),
            ),
            onFavTap: () {
              final isFav = _favoriteIds.contains(property.propertyId);
              if (isFav) {
                context
                    .read<FavoriteBloc>()
                    .add(RemoveFavoriteEvent(property.propertyId));
                setState(() => _favoriteIds.remove(property.propertyId));
              } else {
                context
                    .read<FavoriteBloc>()
                    .add(AddFavoriteEvent(property.propertyId));
                setState(() => _favoriteIds.add(property.propertyId));
              }
            },
            isFavorite: _favoriteIds.contains(property.propertyId),
          );
        },
      );
  }
}
