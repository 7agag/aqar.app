import 'package:aqar/core/navigation/property_detail_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/extensions/num_formatting.dart';
import '../../../../injection_container.dart' as di;
import '../../../ai/data/mappers/ai_property_mapper.dart';
import '../../../ai/domain/usecases/search_ai_properties_usecase.dart';
import '../../../favorite/presentation/bloc/favorite_bloc.dart';
import '../../domain/entities/property_filter_params.dart';
import '../../domain/entities/property_entity.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../widgets/advanced_search_sheet.dart';
import 'package:aqar/features/sponsor/presentation/widgets/sponsored_property_card.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/search_bar_widget.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? _searchText;
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

  bool _isAiSearch = false;
  bool _isAiSearching = false;

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
    if (widget.initialQuery != null) {
      _performSearch(widget.initialQuery!);
    } else {
      _reloadWithFilters();
    }
    _loadFavorites();
  }

  void _loadFavorites() {
    context.read<FavoriteBloc>().add(GetFavoritesEvent());
  }

  void _performSearch(String query) {
    final trimmed = query.trim();
    setState(() {
      _searchText = trimmed.isEmpty ? null : trimmed;
    });
    if (trimmed.isNotEmpty && !_recentSearches.contains(trimmed)) {
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    }
    if (trimmed.isNotEmpty) {
      _searchWithAi(trimmed);
    } else {
      setState(() => _isAiSearch = false);
      _reloadWithFilters();
    }
  }

  Future<void> _searchWithAi(String query) async {
    setState(() => _isAiSearching = true);
    final useCase = di.sl<SearchAiPropertiesUseCase>();
    final result = await useCase(SearchAiPropertiesParams(query: query));
    if (!mounted) return;
    result.fold(
      (failure) {
        // Fallback to regular API with location filter (like React)
        context.read<PropertyBloc>().add(
          GetPropertiesRequested(
            params: PropertyFilterParams(location: query, listingType: _isBuy ? 'forSale' : 'forRent'),
          ),
        );
        setState(() {
          _isAiSearch = false;
          _isAiSearching = false;
        });
      },
      (properties) {
        if (properties.isEmpty) {
          // Fallback to regular API
          context.read<PropertyBloc>().add(
            GetPropertiesRequested(
              params: PropertyFilterParams(location: query, listingType: _isBuy ? 'forSale' : 'forRent'),
            ),
          );
          setState(() {
            _isAiSearch = false;
            _isAiSearching = false;
          });
          return;
        }
          setState(() {
            _isAiSearch = true;
            _isAiSearching = false;
            _filteredProperties = properties.map(mapAiPropertyToEntity).toList();
            // Sort sponsored properties to top (like React)
            _filteredProperties.sort((a, b) {
              if (a.isSponsored == b.isSponsored) return 0;
              return a.isSponsored ? -1 : 1;
            });
          });
      },
    );
  }

  void _reloadWithFilters() {
    if (_isRefreshing) return;
    _isRefreshing = true;

    String? listingType;
    if (_isBuyFilterActive) {
      listingType = _isBuy ? 'forSale' : 'forRent';
    }

    String? effectiveLocation = _activeLocation;
    if (effectiveLocation == null && _searchText != null) {
      effectiveLocation = _searchText;
    }

    context.read<PropertyBloc>().add(
          GetPropertiesRequested(
            params: PropertyFilterParams(
              location: effectiveLocation,
              minPrice: _activeMinPrice,
              maxPrice: _activeMaxPrice,
              bedrooms: _activeBedrooms,
              bathrooms: _activeBathrooms,
              minSize: _activeMinSize,
              maxSize: _activeMaxSize,
              listingType: listingType,
            ),
          ),
        );
  }

  double _getNumericSize(String? sizeStr) {
    if (sizeStr == null || sizeStr.isEmpty) return 0;
    return double.tryParse(sizeStr) ?? 0;
  }

  void _applyClientSort() {
    setState(() {
      switch (_sortBy) {
        case 'price_asc':
          _filteredProperties.sort((a, b) => a.priceValue.compareTo(b.priceValue));
          break;
        case 'price_desc':
          _filteredProperties.sort((a, b) => b.priceValue.compareTo(a.priceValue));
          break;
        case 'size_desc':
          _filteredProperties.sort((a, b) =>
              _getNumericSize(b.size).compareTo(_getNumericSize(a.size)));
          break;
        case 'newest':
        default:
          _filteredProperties.sort((a, b) => b.propertyId.compareTo(a.propertyId));
          break;
      }
    });
  }

  void _openAdvancedSearch() {
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
        allProperties: [],
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
            _isAiSearch = false;
          });
          _reloadWithFilters();
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
                _reloadWithFilters();
              },
              onRemove: () {
                setState(() => _isBuyFilterActive = false);
                _reloadWithFilters();
              },
            ),
          if (_activeLocation != null)
            FilterChipWidget(
              label: 'Location: ${_activeLocation!}',
              isSelected: true,
              onTap: _openAdvancedSearch,
              onRemove: () {
                setState(() => _activeLocation = null);
                _reloadWithFilters();
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
    if (min != null && max != null) return '\$${min.formatWithCommas()} - \$${max.formatWithCommas()}';
    if (min != null) return 'From \$${min.formatWithCommas()}';
    if (max != null) return 'Up to \$${max.formatWithCommas()}';
    return '';
  }

  String get _sizeFilterLabel {
    final min = _activeMinSize?.toInt();
    final max = _activeMaxSize?.toInt();
    if (min != null && max != null) return '${min.formatWithCommas()} - ${max.formatWithCommas()} sqft';
    if (min != null) return 'Min ${min.formatWithCommas()} sqft';
    if (max != null) return 'Max ${max.formatWithCommas()} sqft';
    return '';
  }

  void _clearPriceFilter() {
    setState(() {
      _activeMinPrice = null;
      _activeMaxPrice = null;
    });
    _reloadWithFilters();
  }

  void _clearBedroomsFilter() {
    setState(() => _activeBedrooms = null);
    _reloadWithFilters();
  }

  void _clearBathroomsFilter() {
    setState(() => _activeBathrooms = null);
    _reloadWithFilters();
  }

  void _clearSizeFilter() {
    setState(() {
      _activeMinSize = null;
      _activeMaxSize = null;
    });
    _reloadWithFilters();
  }

  void _clearRentalDurationFilter() {
    setState(() => _activeRentalDuration = null);
    _reloadWithFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Search'),
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
                _filteredProperties = state.allProperties;
                _applyClientSort();
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
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: SearchBarWidget(
                onSubmitted: _performSearch,
                onFilterTap: _openAdvancedSearch,
                hasActiveFilters: _hasActiveAdvancedFilters,
                currentQuery: _searchText,
              ),
            ),
            if (_recentSearches.isNotEmpty && (_searchText == null || _searchText!.isEmpty))
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 4, right: 4),
                      child: Icon(Icons.history, size: 14, color: AppColors.textHint),
                    ),
                    ..._recentSearches.map((q) => GestureDetector(
                      onTap: () {
                        _performSearch(q);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(q, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ),
                    )),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (_isAiSearching)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  if (_isAiSearching)
                    SizedBox(width: 6),
                  if (_isAiSearch)
                    Container(
                      margin: EdgeInsets.only(right: 6),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 10, color: AppColors.primary),
                          SizedBox(width: 3),
                          Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_filteredProperties.isNotEmpty)
                    Text(
                      '${_filteredProperties.length} ${_filteredProperties.length == 1 ? 'result' : 'results'}',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  Spacer(),
                  if (!_isAiSearch)
                    Container(
                      height: 32,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          icon: Icon(Icons.swap_vert, size: 16, color: AppColors.textHint),
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          items: const [
                            DropdownMenuItem(value: 'newest', child: Text('Newest')),
                            DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                            DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                            DropdownMenuItem(value: 'size_desc', child: Text('Largest')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _sortBy = v);
                              _applyClientSort();
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!_isAiSearch) _buildFilters(),
            Expanded(
              child: _filteredProperties.isNotEmpty
                  ? RefreshIndicator(
                      onRefresh: () async {
                        if (_isAiSearch && _searchText != null) {
                          _searchWithAi(_searchText!);
                        } else {
                          _reloadWithFilters();
                        }
                        _loadFavorites();
                      },
                      color: AppColors.primary,
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredProperties.length,
                        itemBuilder: (context, index) {
                          final property = _filteredProperties[index];
                          return SponsoredPropertyCard(
                            property: property,
                            onTap: () {
                              if (property.propertyId > 0) {
                                propertyDetailNavigator.value = property.propertyId;
                              }
                            },
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
                    )
                  : BlocBuilder<PropertyBloc, PropertyState>(
                      buildWhen: (previous, current) {
                        return current is PropertiesLoaded ||
                            current is PropertyLoading ||
                            current is PropertyError;
                      },
                      builder: (context, state) {
                        if (state is PropertyLoading || _isAiSearching) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          );
                        }
                        if (state is PropertiesLoaded) {
                          if (_filteredProperties.isEmpty && !_isAiSearching) {
                            return Center(
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
                        }
                        if (state is PropertyError && !_isAiSearch) {
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
                                  onPressed: _reloadWithFilters,
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
