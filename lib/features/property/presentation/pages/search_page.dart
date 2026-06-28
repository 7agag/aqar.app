// lib/features/property/presentation/pages/search_page.dart

import 'package:aqar/core/navigation/property_detail_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../favorite/presentation/bloc/favorite_bloc.dart';
import '../../domain/entities/property_filter_params.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../widgets/advanced_search_sheet.dart';
import 'package:aqar/features/sponsor/presentation/widgets/sponsored_property_card.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/search_bar_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? _searchText;
  List<PropertyEntity> _allProperties = [];
  List<PropertyEntity> _filteredProperties = [];

  String? _activeLocation;
  double? _activeMinPrice;
  double? _activeMaxPrice;
  int? _activeBedrooms;
  int? _activeBathrooms;
  String? _activeRentalDuration;
  double? _activeMinSize;
  double? _activeMaxSize;

  bool _isBuy = true;
  bool _isBuyFilterActive = false;
  bool _isRefreshing = false;
  Set<int> _favoriteIds = {};

  String _sortBy = 'newest';
  final List<String> _recentSearches = [];

  bool get _hasActiveAdvancedFilters =>
      _activeLocation != null ||
      _activeMinPrice != null ||
      _activeMaxPrice != null ||
      _activeBedrooms != null ||
      _activeBathrooms != null ||
      _activeRentalDuration != null ||
      _activeMinSize != null ||
      _activeMaxSize != null;

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _loadFavorites();
  }

  Future<void> _loadProperties() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    context.read<PropertyBloc>().add(
          GetPropertiesRequested(
            params: const PropertyFilterParams(),
          ),
        );
  }

  void _loadFavorites() {
    context.read<FavoriteBloc>().add(GetFavoritesEvent());
  }

  // ✅ البحث عند الضغط على Enter فقط
  void _performSearch(String query) {
    final trimmed = query.trim();
    setState(() {
      _searchText = trimmed.isEmpty ? null : trimmed;
    });
    if (trimmed.isNotEmpty && !_recentSearches.contains(trimmed)) {
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    }
    _applyFilters();
  }

  double _getNumericSize(String? sizeStr) {
    if (sizeStr == null || sizeStr.isEmpty) return 0;
    return double.tryParse(sizeStr) ?? 0;
  }

  void _applyFilters() {
    var filtered = List<PropertyEntity>.from(_allProperties);

    if (_isBuyFilterActive) {
      final targetType = _isBuy ? ListingType.forSale : ListingType.forRent;
      filtered = filtered.where((p) => p.listingType == targetType).toList();
    }

    if (_searchText != null && _searchText!.isNotEmpty) {
      final searchLower = _searchText!.toLowerCase();
      filtered = filtered
          .where((property) =>
              property.propertyName.toLowerCase().contains(searchLower) ||
              property.location.toLowerCase().contains(searchLower))
          .toList();
    }

    if (_activeLocation != null && _activeLocation!.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.location.toLowerCase().contains(_activeLocation!.toLowerCase()))
          .toList();
    }
    if (_activeMinPrice != null) {
      filtered =
          filtered.where((p) => p.priceValue >= _activeMinPrice!).toList();
    }
    if (_activeMaxPrice != null) {
      filtered =
          filtered.where((p) => p.priceValue <= _activeMaxPrice!).toList();
    }
    if (_activeBedrooms != null && _activeBedrooms! > 0) {
      filtered =
          filtered.where((p) => p.bedroomsNo >= _activeBedrooms!).toList();
    }
    if (_activeBathrooms != null && _activeBathrooms! > 0) {
      filtered =
          filtered.where((p) => p.bathroomsNo >= _activeBathrooms!).toList();
    }
    if (_activeRentalDuration != null && _activeRentalDuration != 'all') {
      filtered = filtered
          .where((p) =>
              p.listingType == ListingType.forRent &&
              p.pricingUnit.value == _activeRentalDuration)
          .toList();
    }
    if (_activeMinSize != null) {
      filtered = filtered
          .where((p) => _getNumericSize(p.size) >= _activeMinSize!)
          .toList();
    }
    if (_activeMaxSize != null) {
      filtered = filtered
          .where((p) => _getNumericSize(p.size) <= _activeMaxSize!)
          .toList();
    }

    switch (_sortBy) {
      case 'price_asc':
        filtered.sort((a, b) => a.priceValue.compareTo(b.priceValue));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.priceValue.compareTo(a.priceValue));
        break;
      case 'size_desc':
        filtered.sort((a, b) =>
            _getNumericSize(b.size).compareTo(_getNumericSize(a.size)));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => b.propertyId.compareTo(a.propertyId));
        break;
    }

    setState(() {
      _filteredProperties = filtered;
    });
  }

  void _openAdvancedSearch() {
    final currentState = context.read<PropertyBloc>().state;
    List<PropertyEntity> allProps = [];
    if (currentState is PropertiesLoaded) {
      allProps = currentState.allProperties;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdvancedSearchSheet(
        isBuy: _isBuy,
        initialLocation: _activeLocation,
        initialMinPrice: _activeMinPrice,
        initialMaxPrice: _activeMaxPrice,
        initialBedrooms: _activeBedrooms,
        initialBathrooms: _activeBathrooms,
        initialRentalDuration: _activeRentalDuration,
        initialMinSize: _activeMinSize,
        initialMaxSize: _activeMaxSize,
        allProperties: allProps,
        onApply: (filter) {
          setState(() {
            _isBuy = filter.isBuy;
            _isBuyFilterActive = true;
            _activeLocation = filter.location;
            _activeMinPrice = filter.minPrice;
            _activeMaxPrice = filter.maxPrice;
            _activeBedrooms = filter.bedrooms;
            _activeBathrooms = filter.bathrooms;
            _activeRentalDuration = filter.rentalDuration;
            _activeMinSize = filter.minSize;
            _activeMaxSize = filter.maxSize;
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildFilters() {
    if (!_hasVisibleFilterChips) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_isBuyFilterActive)
            FilterChipWidget(
              label: _isBuy ? 'Buy' : 'Rent',
              isSelected: true,
              onTap: () {
                setState(() => _isBuy = !_isBuy);
                _applyFilters();
              },
              onRemove: () {
                setState(() => _isBuyFilterActive = false);
                _applyFilters();
              },
            ),
          if (_activeLocation != null)
            FilterChipWidget(
              label: 'Location: ${_activeLocation!}',
              isSelected: true,
              onTap: _openAdvancedSearch,
              onRemove: () {
                setState(() => _activeLocation = null);
                _applyFilters();
              },
            ),
          if (_activeMinPrice != null || _activeMaxPrice != null)
            FilterChipWidget(
              label: _priceFilterLabel,
              isSelected: true,
              onTap: _openAdvancedSearch,
              onRemove: _clearPriceFilter,
            ),
          if (_activeRentalDuration != null && _activeRentalDuration != 'all')
            FilterChipWidget(
              label: _activeRentalDuration!,
              isSelected: true,
              onTap: _openAdvancedSearch,
              onRemove: _clearRentalDurationFilter,
            ),
          if (_activeBedrooms != null && _activeBedrooms! > 0)
            FilterChipWidget(
              label: '$_activeBedrooms+ Bedrooms',
              isSelected: true,
              onTap: _openAdvancedSearch,
              onRemove: _clearBedroomsFilter,
            ),
          if (_activeBathrooms != null && _activeBathrooms! > 0)
            FilterChipWidget(
              label: '$_activeBathrooms+ Bathrooms',
              isSelected: true,
              onTap: _openAdvancedSearch,
              onRemove: _clearBathroomsFilter,
            ),
          if (_activeMinSize != null || _activeMaxSize != null)
            FilterChipWidget(
              label: _sizeFilterLabel,
              isSelected: true,
              onTap: _openAdvancedSearch,
              onRemove: _clearSizeFilter,
            ),
        ],
      ),
    );
  }

  bool get _hasVisibleFilterChips =>
      _isBuyFilterActive ||
      _activeLocation != null ||
      _activeMinPrice != null ||
      _activeMaxPrice != null ||
      (_activeRentalDuration != null && _activeRentalDuration != 'all') ||
      (_activeBedrooms != null && _activeBedrooms! > 0) ||
      (_activeBathrooms != null && _activeBathrooms! > 0) ||
      _activeMinSize != null ||
      _activeMaxSize != null;

  String get _priceFilterLabel {
    final min = _activeMinPrice?.toInt();
    final max = _activeMaxPrice?.toInt();
    if (min != null && max != null) return '\$$min - \$$max';
    if (min != null) return 'From \$$min';
    if (max != null) return 'Up to \$$max';
    return '';
  }

  String get _sizeFilterLabel {
    final min = _activeMinSize?.toInt();
    final max = _activeMaxSize?.toInt();
    if (min != null && max != null) return '$min - $max sqft';
    if (min != null) return 'Min $min sqft';
    if (max != null) return 'Max $max sqft';
    return '';
  }

  void _clearPriceFilter() {
    setState(() {
      _activeMinPrice = null;
      _activeMaxPrice = null;
    });
    _applyFilters();
  }

  void _clearBedroomsFilter() {
    setState(() => _activeBedrooms = null);
    _applyFilters();
  }

  void _clearBathroomsFilter() {
    setState(() => _activeBathrooms = null);
    _applyFilters();
  }

  void _clearSizeFilter() {
    setState(() {
      _activeMinSize = null;
      _activeMaxSize = null;
    });
    _applyFilters();
  }

  void _clearRentalDurationFilter() {
    setState(() => _activeRentalDuration = null);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<PropertyBloc, PropertyState>(
            listener: (context, state) {
              if (state is PropertiesLoaded) {
                _isRefreshing = false;
                if (_allProperties != state.allProperties) {
                  _allProperties = state.allProperties;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _applyFilters();
                  });
                }
              }
              if (state is PropertyError) {
                _isRefreshing = false;
              }
            },
          ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: SearchBarWidget(
                onSubmitted: _performSearch,
                onFilterTap: _openAdvancedSearch,
                hasActiveFilters: _hasActiveAdvancedFilters,
                currentQuery: _searchText,
              ),
            ),
            if (_recentSearches.isNotEmpty && (_searchText == null || _searchText!.isEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 4),
                      child: Icon(Icons.history, size: 14, color: AppColors.textHint),
                    ),
                    ..._recentSearches.map((q) => GestureDetector(
                      onTap: () {
                        _performSearch(q);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(q, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ),
                    )),
                  ],
                ),
              ),
            // Sort + Results count row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (_filteredProperties.isNotEmpty)
                    Text(
                      '${_filteredProperties.length} ${_filteredProperties.length == 1 ? 'result' : 'results'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  const Spacer(),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        icon: const Icon(Icons.swap_vert, size: 16, color: AppColors.textHint),
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        items: const [
                          DropdownMenuItem(value: 'newest', child: Text('Newest')),
                          DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                          DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                          DropdownMenuItem(value: 'size_desc', child: Text('Largest')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _sortBy = v);
                            _applyFilters();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildFilters(),
            Expanded(
              child: BlocBuilder<PropertyBloc, PropertyState>(
                buildWhen: (previous, current) {
                  return current is PropertiesLoaded ||
                      current is PropertyLoading ||
                      current is PropertyError;
                },
                builder: (context, state) {
                  if (state is PropertyLoading && _allProperties.isEmpty) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (state is PropertiesLoaded) {
                    if (_filteredProperties.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: AppColors.textHint),
                            SizedBox(height: 16),
                            Text(
                              'No results found',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        await _loadProperties();
                        _loadFavorites();
                      },
                      color: AppColors.primary,
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredProperties.length,
                        itemBuilder: (context, index) {
                          final property = _filteredProperties[index];
                          return SponsoredPropertyCard(
                            property: property,
                            onTap: () =>
                                propertyDetailNavigator.value = property.propertyId,
                            onFavTap: () {
                              final isFav =
                                  _favoriteIds.contains(property.propertyId);
                              if (isFav) {
                                context.read<FavoriteBloc>().add(
                                    RemoveFavoriteEvent(property.propertyId));
                                setState(() =>
                                    _favoriteIds.remove(property.propertyId));
                              } else {
                                context
                                    .read<FavoriteBloc>()
                                    .add(AddFavoriteEvent(property.propertyId));
                                setState(() =>
                                    _favoriteIds.add(property.propertyId));
                              }
                            },
                            isFavorite:
                                _favoriteIds.contains(property.propertyId),
                          );
                        },
                      ),
                    );
                  }
                  if (state is PropertyError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.message,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadProperties,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
