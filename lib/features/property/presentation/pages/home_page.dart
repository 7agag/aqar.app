// lib/features/property/presentation/pages/home_page.dart

import 'package:aqar/features/favorite/presentation/bloc/favorite_bloc.dart';
import 'package:aqar/features/favorite/presentation/pages/favorites_page.dart';
import 'package:aqar/features/map/presentation/pages/map_page.dart';
import 'package:aqar/features/property/presentation/pages/search_page.dart';
import 'package:aqar/features/auth/presentation/pages/profile_page.dart';
import 'package:aqar/features/property/presentation/pages/all_properties_page.dart';
import 'package:aqar/features/property/presentation/pages/property_detail_page.dart';
import 'package:aqar/features/ai/presentation/pages/ai_assistant_page.dart';
import 'package:aqar/features/notifications/presentation/pages/notifications_page.dart';
import 'package:aqar/features/chat/presentation/pages/chat_list_page.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/pages/rent_requests_page.dart';
import 'package:aqar/features/auth/presentation/widgets/auth_guard.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_state.dart';
import 'package:aqar/core/navigation/property_detail_navigator.dart';
import 'package:aqar/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/refreshable_widget.dart';
import '../../domain/entities/property_filter_params.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../widgets/advanced_search_sheet.dart';
import '../widgets/sponsored_property_card.dart';
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

  // Advanced filters (بدون Location)
  double? _activeMinPrice;
  double? _activeMaxPrice;
  int? _activeBedrooms;
  int? _activeBathrooms;
  String? _activeRentalDuration;
  double? _activeMinSize;
  double? _activeMaxSize;

  int? _detailPropertyId;
  bool _showDetail = false;

  // Loading
  bool _isLoading = false;

  List<PropertyEntity> _allProperties = [];

  bool get _hasActiveAdvancedFilters =>
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

  // ========== البحث (عند الضغط على Enter فقط) ==========
  void _performSearch(String query) {
    setState(() {
      _searchText = query.trim().isEmpty ? null : query.trim();
      _nearbyCache = null;
    });
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
            _activeMinPrice = filter.minPrice;
            _activeMaxPrice = filter.maxPrice;
            _activeBedrooms = filter.bedrooms;
            _activeBathrooms = filter.bathrooms;
            _activeRentalDuration = filter.rentalDuration;
            _activeMinSize = filter.minSize;
            _activeMaxSize = filter.maxSize;
          });
        },
      ),
    );
  }

  // ========== مسح الفلاتر ==========
  void _clearPriceFilter() {
    setState(() {
      _activeMinPrice = null;
      _activeMaxPrice = null;
    });
  }

  void _clearBedroomsFilter() {
    setState(() {
      _activeBedrooms = null;
    });
  }

  void _clearBathroomsFilter() {
    setState(() {
      _activeBathrooms = null;
    });
  }

  void _clearSizeFilter() {
    setState(() {
      _activeMinSize = null;
      _activeMaxSize = null;
    });
  }

  void _clearRentalDurationFilter() {
    setState(() {
      _activeRentalDuration = null;
    });
  }

  void _clearAllFilters() {
    setState(() {
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
    propertyDetailNavigator.addListener(_onDetailNavigatorChanged);
  }

  @override
  void dispose() {
    propertyDetailNavigator.removeListener(_onDetailNavigatorChanged);
    super.dispose();
  }

  void _onDetailNavigatorChanged() {
    final value = propertyDetailNavigator.value;
    setState(() {
      if (value != null) {
        _detailPropertyId = value;
        _showDetail = true;
      } else {
        _showDetail = false;
      }
    });
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
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthProfileLoaded) {
      context.read<FavoriteBloc>().add(GetFavoritesEvent());
    }
  }

  void _toggleFavorite(int propertyId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthProfileLoaded) {
      Navigator.pushNamed(context, '/auth');
      return;
    }
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
      _allProperties = [];
      _clearNearbyCache();
    });
    _loadProperties();
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildFilters()),
            SliverToBoxAdapter(child: _buildBuyRentToggle()),
            SliverToBoxAdapter(child: _buildSponsoredSection()),
            SliverToBoxAdapter(child: _buildNearbySection()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // UI components
  // ----------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/icons/aqar.png', height: 32),
              const SizedBox(width: 8),
              const Text(
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
              IconButton(
                onPressed: () {
                  _loadProperties();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyRequestsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.inbox_outlined,
                    color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: () {
                  _loadProperties();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChatListPage()));
                },
                icon: const Icon(Icons.chat_outlined,
                    color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is! AuthProfileLoaded) {
                    Navigator.pushNamed(context, '/auth');
                    return;
                  }
                  _loadProperties();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsPage()));
                },
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary),
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

  Widget _buildBuyRentToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
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
    double cardWidth = screenWidth * 0.42;
    if (cardWidth > 260) cardWidth = 260;
    if (cardWidth < 180) cardWidth = 180;
    final double cardHeight = (cardWidth * 0.6) + 90;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 18, color: const Color(0xFFD4AF37)),
              const SizedBox(width: 6),
              const Text(
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
              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'No sponsored listings',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
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
    return RefreshableWidget(
      onRefresh: _loadProperties,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeContent(),
                const SearchPage(),
                const MapPage(),
                const FavoritesPage(),
                const ProfilePage(),
              ],
            ),
            if (_detailPropertyId != null)
              Positioned.fill(
                child: Visibility(
                  visible: _showDetail,
                  maintainState: true,
                  child: PropertyDetailPage(
                    propertyId: _detailPropertyId!,
                    onBack: () {
                      propertyDetailNavigator.value = null;
                    },
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => requireVerifiedUser(
            context,
            onAllowed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AiAssistantPage())),
          ),
          backgroundColor: AppColors.textPrimary,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
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
            ],
          ),
        ),
      ),
    );
  }
}
