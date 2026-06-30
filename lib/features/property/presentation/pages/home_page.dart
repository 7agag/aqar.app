// lib/features/property/presentation/pages/home_page.dart

import 'package:aqar/core/extensions/num_formatting.dart';
import 'package:aqar/features/favorite/presentation/bloc/favorite_bloc.dart';
import 'package:aqar/features/favorite/presentation/pages/favorites_page.dart';
import 'package:aqar/features/map/presentation/pages/map_page.dart';
import 'package:aqar/features/property/presentation/pages/search_page.dart';
import 'package:aqar/features/auth/presentation/pages/profile_page.dart';
import 'package:aqar/features/inbox/presentation/pages/inbox_page.dart';
import 'package:aqar/features/property/presentation/pages/all_properties_page.dart';
import 'package:aqar/features/property/presentation/pages/property_detail_page.dart';
import 'package:aqar/features/ai/presentation/pages/ai_assistant_page.dart';
import 'package:aqar/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:aqar/features/ai/presentation/bloc/ai_state.dart';
import 'package:aqar/features/notifications/presentation/pages/notifications_page.dart';
import 'package:aqar/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:aqar/features/notifications/presentation/bloc/notification_event.dart';
import 'package:aqar/features/notifications/presentation/bloc/notification_state.dart';
import 'package:aqar/features/payment/presentation/widgets/rent_due_banner.dart';
import 'package:aqar/features/chat/presentation/pages/chat_list_page.dart';
import 'package:aqar/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:aqar/features/chat/presentation/bloc/chat_event.dart';
import 'package:aqar/features/chat/presentation/bloc/chat_state.dart';
import 'package:aqar/features/rent_request/presentation/pages/rent_requests_page.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_event.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_state.dart';
import 'package:aqar/features/auth/presentation/widgets/auth_guard.dart';
import 'package:aqar/core/navigation/property_detail_navigator.dart';
import 'package:aqar/core/services/ai_unread_service.dart';
import 'package:aqar/core/widgets/badge_icon.dart';
import 'package:aqar/injection_container.dart' as di;
import 'package:aqar/features/ai/data/mappers/ai_property_mapper.dart';
import 'package:aqar/features/ai/domain/usecases/search_ai_properties_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/property_filter_params.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../widgets/advanced_search_sheet.dart';
import 'package:aqar/features/sponsor/presentation/widgets/sponsored_property_card.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/nearby_property_card.dart';
import '../widgets/search_bar_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _currentIndex = 0;

  // --- search & filters ---
  String? _searchText;
  bool _isBuy = true;
  int _buyCount = 0;
  int _rentCount = 0;
  Set<int> _favoriteIds = {};

  // Advanced filters
  String? _activeLocation;
  double? _activeMinPrice;
  double? _activeMaxPrice;
  int? _activeBedrooms;
  int? _activeBathrooms;
  String? _activeRentalDuration;
  double? _activeMinSize;
  double? _activeMaxSize;

  bool _isAiSearch = false;
  bool _isAiSearching = false;
  List<PropertyEntity> _aiSearchResults = [];

  bool _aiHasUnread = false;

  // Loading
  bool _isLoading = false;

  List<PropertyEntity> _allProperties = [];

  bool get _hasActiveAdvancedFilters =>
      _activeLocation != null ||
      _activeMinPrice != null ||
      _activeMaxPrice != null ||
      _activeBedrooms != null ||
      _activeBathrooms != null ||
      _activeRentalDuration != null ||
      _activeMinSize != null ||
      _activeMaxSize != null;

  // (local filtering removed — sponsored & nearby use independent getters)

  ListingType _listingTypeOf(PropertyEntity property) {
    final ls = property.listingStatus?.value;
    if (ls == 'for_sale' || ls == 'for_rent') return ListingType.fromValue(ls!);

    final pt = property.listingType.value;
    if (pt == 'for_sale' || pt == 'for_rent') return ListingType.fromValue(pt);

    return property.isAvailable ? ListingType.forRent : ListingType.forSale;
  }

  void _updateBuyRentCounts(List<PropertyEntity> properties) {
    _buyCount = properties
        .where((property) => _listingTypeOf(property) == ListingType.forSale)
        .length;
    _rentCount = properties
        .where((property) => _listingTypeOf(property) == ListingType.forRent)
        .length;
  }

  bool _matchesSearch(PropertyEntity p) {
    if (_searchText == null) return true;
    final q = _searchText!.toLowerCase();
    return p.propertyName.toLowerCase().contains(q) ||
        p.location.toLowerCase().contains(q);
  }

  double _numericSizeOf(PropertyEntity property) {
    return double.tryParse(property.size) ?? 0;
  }

  bool _matchesActiveFilters(PropertyEntity property) {
    if (!_matchesSearch(property)) return false;
    if (_activeMinPrice != null && property.priceValue < _activeMinPrice!) {
      return false;
    }
    if (_activeMaxPrice != null && property.priceValue > _activeMaxPrice!) {
      return false;
    }
    if (_activeBedrooms != null &&
        _activeBedrooms! > 0 &&
        property.bedroomsNo < _activeBedrooms!) {
      return false;
    }
    if (_activeBathrooms != null &&
        _activeBathrooms! > 0 &&
        property.bathroomsNo < _activeBathrooms!) {
      return false;
    }
    if (_activeRentalDuration != null &&
        _activeRentalDuration != 'all' &&
        property.pricingUnit.value != _activeRentalDuration) {
      return false;
    }

    final size = _numericSizeOf(property);
    if (_activeMinSize != null && size < _activeMinSize!) return false;
    if (_activeMaxSize != null && size > _activeMaxSize!) return false;

    return true;
  }

  List<PropertyEntity> get _sponsoredProperties => _allProperties
      .where((p) =>
          p.isSponsored &&
          p.listingType ==
              (_isBuy ? ListingType.forSale : ListingType.forRent) &&
          _matchesActiveFilters(p))
      .toList();

  List<PropertyEntity>? _nearbyCache;

  List<PropertyEntity> get _nearbyProperties {
    if (_nearbyCache != null) return _nearbyCache!;
    final nonSponsored = _allProperties
        .where((p) =>
            !p.isSponsored &&
            p.listingType ==
                (_isBuy ? ListingType.forSale : ListingType.forRent) &&
            _matchesActiveFilters(p))
        .toList();
    nonSponsored.shuffle();
    _nearbyCache = nonSponsored;
    return nonSponsored;
  }

  void _clearNearbyCache() {
    _nearbyCache = null;
  }

  // ========== تحميل البيانات ==========
  Future<void> _loadProperties() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _allProperties = [];
    });

    context.read<PropertyBloc>().add(
          GetPropertiesRequested(
            params: const PropertyFilterParams(),
          ),
        );
  }

  void _reloadWithFilters() {
    if (_isLoading) return;

    String? listingType = _isBuy ? 'forSale' : 'forRent';
    String? effectiveLocation = _activeLocation ?? _searchText?.trim();
    if (effectiveLocation != null && effectiveLocation.isEmpty) {
      effectiveLocation = null;
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
              rentalDuration: _activeRentalDuration,
            ),
          ),
        );
  }

  void _performSearch(String query) {
    final trimmed = query.trim();
    setState(() {
      _searchText = trimmed.isEmpty ? null : trimmed;
    });
    if (trimmed.isNotEmpty) {
      _searchWithAi(trimmed);
    } else {
      setState(() {
        _isAiSearch = false;
        _aiSearchResults = [];
      });
    }
  }

  Future<void> _searchWithAi(String query) async {
    setState(() => _isAiSearching = true);
    final useCase = di.sl<SearchAiPropertiesUseCase>();
    final result = await useCase(SearchAiPropertiesParams(query: query));
    if (!mounted) return;
    result.fold(
      (failure) {
        // Fallback to regular API search (like React does)
        context.read<PropertyBloc>().add(
          GetPropertiesRequested(
            params: PropertyFilterParams(location: query),
          ),
        );
        setState(() {
          _isAiSearch = false;
          _isAiSearching = false;
        });
      },
      (properties) {
        if (properties.isEmpty) {
          // Fallback to regular API search
          context.read<PropertyBloc>().add(
            GetPropertiesRequested(
              params: PropertyFilterParams(location: query),
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
          _aiSearchResults = properties.map(mapAiPropertyToEntity).toList();
        });
      },
    );
  }

  // ========== الفلاتر المتقدمة ==========
  void _onFilterTap() {
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
            _activeLocation = filter.location;
            _activeMinPrice = filter.minPrice;
            _activeMaxPrice = filter.maxPrice;
            _activeBedrooms = filter.bedrooms;
            _activeBathrooms = filter.bathrooms;
            _activeRentalDuration = filter.rentalDuration;
            _activeMinSize = filter.minSize;
            _activeMaxSize = filter.maxSize;
          });
          _reloadWithFilters();
        },
      ),
    );
  }

  // ========== مسح الفلاتر ==========
  void _clearLocationFilter() {
    setState(() {
      _activeLocation = null;
    });
    _reloadWithFilters();
  }

  void _clearPriceFilter() {
    setState(() {
      _activeMinPrice = null;
      _activeMaxPrice = null;
    });
    _reloadWithFilters();
  }

  void _clearBedroomsFilter() {
    setState(() {
      _activeBedrooms = null;
    });
    _reloadWithFilters();
  }

  void _clearBathroomsFilter() {
    setState(() {
      _activeBathrooms = null;
    });
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
    setState(() {
      _activeRentalDuration = null;
    });
    _reloadWithFilters();
  }

  void _clearAllFilters() {
    setState(() {
      _activeLocation = null;
      _activeMinPrice = null;
      _activeMaxPrice = null;
      _activeBedrooms = null;
      _activeBathrooms = null;
      _activeRentalDuration = null;
      _activeMinSize = null;
      _activeMaxSize = null;
    });
    _loadProperties();
  }

  // _navigateToAllProperties removed — "Explore More" in nearby section uses inline navigation

  // ========== دورة الحياة ==========
  @override
  void initState() {
    super.initState();
    _favoriteIds = {};
    _loadProperties();
    _loadCounts();
    _loadFavorites();
    context.read<ChatBloc>().add(const GetInboxRequested());
    context.read<NotificationBloc>().add(const GetNotificationsRequested());
    context.read<RentRequestBloc>().add(const LoadRentRequests());
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ========== تحميل الأعداد والمفضلة ==========
  Future<void> _loadCounts() async {
    final result = await context.read<PropertyBloc>().getPropertiesDirectly(
          PropertyFilterParams(),
        );

    result.fold(
      (_) {},
      (properties) {
        if (!mounted) return;
        setState(() {
          _updateBuyRentCounts(properties);
        });
      },
    );
  }

  void _loadFavorites() {
    context.read<FavoriteBloc>().add(GetFavoritesEvent());
  }

  void _toggleFavorite(int propertyId) {
    final isFav = _favoriteIds.contains(propertyId);
    if (isFav) {
      context.read<FavoriteBloc>().add(RemoveFavoriteEvent(propertyId));
      setState(() => _favoriteIds.remove(propertyId));
    } else {
      context.read<FavoriteBloc>().add(AddFavoriteEvent(propertyId));
      setState(() => _favoriteIds.add(propertyId));
    }
  }

  // ========== تبديل Buy/Rent ==========
  void _toggleBuyRent(bool isBuy) {
    setState(() {
      _isBuy = isBuy;
      _clearNearbyCache();
    });
    _reloadWithFilters();
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 0 || index == 1) {
      _loadProperties();
    }
  }

  // ----------------------------------------------------------------------
  // HOME CONTENT
  // ----------------------------------------------------------------------
  Widget _buildHomeContent() {
    return MultiBlocListener(
      listeners: [
        BlocListener<PropertyBloc, PropertyState>(
          listener: (context, state) {
            if (state is PropertiesLoaded) {
              setState(() {
                _allProperties = state.allProperties;
                _isLoading = false;
                _updateBuyRentCounts(state.allProperties);
                _clearNearbyCache();
              });
            }
            if (state is PropertyError) {
              _isLoading = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
        BlocListener<FavoriteBloc, FavoriteState>(
          listener: (context, state) {
            if (state is FavoriteLoaded) {
              setState(() {
                _favoriteIds = state.favorites.map((p) => p.propertyId).toSet();
              });
            } else if (state is FavoriteOperationSuccess) {
              _loadFavorites();
            }
          },
        ),
      ],
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isAiSearching
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _isAiSearch
                      ? _buildAiSearchResults()
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(child: _buildFilters()),
                            SliverToBoxAdapter(child: _buildBuyRentToggle()),
                            SliverToBoxAdapter(child: _buildSponsoredSection()),
                            SliverToBoxAdapter(child: _buildNearbySection()),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 100)),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSearchResults() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'AI Search',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${_aiSearchResults.length} ${_aiSearchResults.length == 1 ? 'result' : 'results'}',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAiSearch = false;
                    _aiSearchResults = [];
                    _searchText = null;
                  });
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 12, color: AppColors.textHint),
                      SizedBox(width: 4),
                      Text(
                        'Clear',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _searchWithAi(_searchText ?? ''),
            color: AppColors.primary,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _aiSearchResults.length,
              itemBuilder: (context, index) {
                final property = _aiSearchResults[index];
                return SponsoredPropertyCard(
                  property: property,
                  onTap: () {
                    if (property.propertyId > 0) {
                      propertyDetailNavigator.value = property.propertyId;
                    }
                  },
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
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // UI components
  // ----------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/icons/aqar.png', height: 32),
              SizedBox(width: 8),
              Text(
                'AQAR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              BlocBuilder<RentRequestBloc, RentRequestState>(
                builder: (context, state) {
                  final count = state is RentRequestsLoaded
                      ? (state.sent
                              .where((r) => r.state.name == 'pending')
                              .length +
                          state.received
                              .where((r) => r.state.name == 'pending')
                              .length)
                      : 0;
                  return BadgeIcon(
                    icon: Icons.inbox_outlined,
                    count: count,
                    badgeColor: const Color(0xFFE67E22),
                    onPressed: () {
                      _loadProperties();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyRequestsPage(),
                        ),
                      );
                    },
                  );
                },
              ),
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  final count = state is InboxLoaded
                      ? state.threads
                          .fold<int>(0, (sum, t) => sum + t.unreadCount)
                      : 0;
                  return BadgeIcon(
                    icon: Icons.chat_outlined,
                    count: count,
                    badgeColor: const Color(0xFF3498DB),
                    onPressed: () {
                      _loadProperties();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChatListPage()));
                    },
                  );
                },
              ),
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  final count =
                      state is NotificationsLoaded ? state.unreadCount : 0;
                  return BadgeIcon(
                    icon: Icons.notifications_outlined,
                    count: count,
                    badgeColor: AppColors.error,
                    onPressed: () {
                      _loadProperties();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsPage()));
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SearchBarWidget(
        onSubmitted: _performSearch, // ✅ البحث عند Enter
        onFilterTap: _onFilterTap,
        hasActiveFilters: _hasActiveAdvancedFilters,
        currentQuery: _searchText,
      ),
    );
  }

  Widget _buildFilters() {
    if (!_hasVisibleFilterChips) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_activeLocation != null)
              FilterChipWidget(
                label: 'Location: $_activeLocation',
                isSelected: true,
                onTap: _onFilterTap,
                onRemove: _clearLocationFilter,
              ),
            if (_activeMinPrice != null || _activeMaxPrice != null)
              FilterChipWidget(
                label: _priceFilterLabel,
                isSelected: true,
                onTap: _onFilterTap,
                onRemove: _clearPriceFilter,
              ),
            if (_activeRentalDuration != null && _activeRentalDuration != 'all')
              FilterChipWidget(
                label: _activeRentalDuration!,
                isSelected: true,
                onTap: _onFilterTap,
                onRemove: _clearRentalDurationFilter,
              ),
            if (_activeBedrooms != null && _activeBedrooms! > 0)
              FilterChipWidget(
                label: '$_activeBedrooms+ Bedrooms',
                isSelected: true,
                onTap: _onFilterTap,
                onRemove: _clearBedroomsFilter,
              ),
            if (_activeBathrooms != null && _activeBathrooms! > 0)
              FilterChipWidget(
                label: '$_activeBathrooms+ Bathrooms',
                isSelected: true,
                onTap: _onFilterTap,
                onRemove: _clearBathroomsFilter,
              ),
            if (_activeMinSize != null || _activeMaxSize != null)
              FilterChipWidget(
                label: _sizeFilterLabel,
                isSelected: true,
                onTap: _onFilterTap,
                onRemove: _clearSizeFilter,
              ),
            if (_hasActiveAdvancedFilters)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _hasVisibleFilterChips =>
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
    if (min != null && max != null) {
      return '\$${min.formatWithCommas()} - \$${max.formatWithCommas()}';
    }
    if (min != null) return 'From \$${min.formatWithCommas()}';
    if (max != null) return 'Up to \$${max.formatWithCommas()}';
    return '';
  }

  String get _sizeFilterLabel {
    final min = _activeMinSize?.toInt();
    final max = _activeMaxSize?.toInt();
    if (min != null && max != null) {
      return '${min.formatWithCommas()} - ${max.formatWithCommas()} sqft';
    }
    if (min != null) return 'Min ${min.formatWithCommas()} sqft';
    if (max != null) return 'Max ${max.formatWithCommas()} sqft';
    return '';
  }

  Widget _buildBuyRentToggle() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            _toggleTab('Buy', _isBuy, () => _toggleBuyRent(true)),
            _toggleTab('Rent', !_isBuy, () => _toggleBuyRent(false)),
          ],
        ),
      ),
    );
  }

  Widget _toggleTab(String label, bool active, VoidCallback onTap) {
    final count = label == 'Buy' ? _buyCount : _rentCount;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ========== Sponsored Section ==========
  Widget _buildSponsoredSection() {
    final sponsored = _sponsoredProperties;
    final screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth * 0.48;
    if (cardWidth > 300) cardWidth = 300;
    if (cardWidth < 180) cardWidth = 180;
    final double cardHeight = (cardWidth * 0.58) + 105;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 18, color: Color(0xFFD4AF37)),
              SizedBox(width: 6),
              Text(
                'Sponsored Properties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (sponsored.isEmpty)
          _buildSponsoredEmpty(cardHeight)
        else
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              itemCount: sponsored.length,
              itemBuilder: (context, index) {
                final property = sponsored[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SponsoredPropertyCard(
                    property: property,
                    onTap: () {
                      propertyDetailNavigator.value = property.propertyId;
                    },
                    onFavTap: () => _toggleFavorite(property.propertyId),
                    isFavorite: _favoriteIds.contains(property.propertyId),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSponsoredEmpty(double height) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 40,
              color: Color(0xFFD4AF37).withValues(alpha: 0.4),
            ),
            SizedBox(height: 8),
            Text(
              'No sponsored listings',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Premium properties appear here',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== Nearby Section ==========
  Widget _buildNearbySection() {
    final nearby = _nearbyProperties;
    if (nearby.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Properties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllPropertiesPage(
                      pageType: _isBuy ? PageType.sale : PageType.rent,
                    ),
                  ),
                ),
                child: const Text(
                  'Explore More',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: nearby.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final property = nearby[index];
            return NearbyPropertyCard(
              property: property,
              onTap: () => propertyDetailNavigator.value = property.propertyId,
              onFavTap: () => _toggleFavorite(property.propertyId),
              isFavorite: _favoriteIds.contains(property.propertyId),
            );
          },
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // MAIN BUILD
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AiBloc, AiState>(
        listener: (context, state) {
          final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
          if (state is AiLoaded &&
              !state.isLoading &&
              state.notifyUnread &&
              isCurrentRoute) {
            final lastMsg =
                state.messages.isNotEmpty ? state.messages.last : null;
            if (lastMsg != null && !lastMsg.isUser) {
              AiUnreadService().setHasUnread(true);
              setState(() => _aiHasUnread = true);
            }
          }
        },
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x0FD4AF37),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeContent(),
                const SearchPage(),
                const MapPage(),
                const FavoritesPage(),
                const ProfilePage(),
                const InboxPage(),
              ],
            ),
            ValueListenableBuilder<int?>(
              valueListenable: propertyDetailNavigator,
              builder: (context, detailId, _) {
                if (detailId == null) return const SizedBox.shrink();
                return Positioned.fill(
                  child: PropertyDetailPage(
                    propertyId: detailId,
                    onBack: () {
                      propertyDetailNavigator.value = null;
                    },
                  ),
                );
              },
            ),
            const RentDueBanner(),
          ],
        ),
      ),
      floatingActionButton: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            onPressed: () => requireVerifiedUser(
              context,
              onAllowed: () {
                AiUnreadService().clear();
                setState(() => _aiHasUnread = false);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AiAssistantPage()));
              },
            ),
            backgroundColor: AppColors.textPrimary,
            shape: CircleBorder(),
            child: Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (_aiHasUnread)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Color(0xFF2ECC71),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _selectTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'SEARCH',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: 'MAP',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              label: 'SAVED',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'PROFILE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inbox_rounded),
              label: 'INBOX',
            ),
          ],
        ),
      ),
    );
  }
}
