import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../widgets/featured_property_card.dart';
import '../widgets/nearby_property_card.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/advanced_search_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isBuy = true;
  int _currentIndex = 0;

  // Active filters
  String? _activeLocation;
  double? _activeMinPrice;
  double? _activeMaxPrice;
  int? _activeBedrooms;
  int? _activeBathrooms;
  String? _activePropertyType;

  bool get _hasActiveAdvancedFilters =>
      _activeMinPrice != null ||
      _activeMaxPrice != null ||
      _activeBedrooms != null ||
      _activeBathrooms != null ||
      _activePropertyType != null;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  void _loadProperties({
    String? location,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
    String? propertyType,
  }) {
    context.read<PropertyBloc>().add(
          GetPropertiesRequested(
            location: location,
            minPrice: minPrice,
            maxPrice: maxPrice,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            propertyType: propertyType,
          ),
        );
  }

  void _onSearch(String query) {
    _activeLocation = query.isNotEmpty ? query : null;
    _loadProperties(
      location: _activeLocation,
      minPrice: _activeMinPrice,
      maxPrice: _activeMaxPrice,
      bedrooms: _activeBedrooms,
      bathrooms: _activeBathrooms,
      propertyType: _activePropertyType,
    );
  }

  void _onFilterTap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdvancedSearchSheet(
        initialLocation: _activeLocation,
        initialMinPrice: _activeMinPrice,
        initialMaxPrice: _activeMaxPrice,
        initialBedrooms: _activeBedrooms,
        initialBathrooms: _activeBathrooms,
        initialPropertyType: _activePropertyType,
        onApply: ({
          location,
          minPrice,
          maxPrice,
          bedrooms,
          bathrooms,
          propertyType,
        }) {
          setState(() {
            _activeLocation = location;
            _activeMinPrice = minPrice;
            _activeMaxPrice = maxPrice;
            _activeBedrooms = bedrooms;
            _activeBathrooms = bathrooms;
            _activePropertyType = propertyType;
          });
          _loadProperties(
            location: location,
            minPrice: minPrice,
            maxPrice: maxPrice,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            propertyType: propertyType,
          );
        },
      ),
    );
  }

  void _reloadWithActiveFilters() {
    _loadProperties(
      location: _activeLocation,
      minPrice: _activeMinPrice,
      maxPrice: _activeMaxPrice,
      bedrooms: _activeBedrooms,
      bathrooms: _activeBathrooms,
      propertyType: _activePropertyType,
    );
  }

  void _clearPriceFilter() {
    setState(() {
      _activeMinPrice = null;
      _activeMaxPrice = null;
    });
    _reloadWithActiveFilters();
  }

  void _clearPropertyTypeFilter() {
    setState(() => _activePropertyType = null);
    _reloadWithActiveFilters();
  }

  void _clearBedroomsFilter() {
    setState(() => _activeBedrooms = null);
    _reloadWithActiveFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildFilters()),
            SliverToBoxAdapter(child: _buildBuyRentToggle()),
            SliverToBoxAdapter(child: _buildFeaturedSection()),
            SliverToBoxAdapter(child: _buildNearbySection()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      // Chatbot FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: open chatbot
        },
        backgroundColor: AppColors.textPrimary,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.smart_toy_outlined,
          color: Colors.white,
          size: 24,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SearchBarWidget(
        onSearch: _onSearch,
        onFilterTap: _onFilterTap,
        hasActiveFilters: _hasActiveAdvancedFilters,
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
            if (_activeMinPrice != null || _activeMaxPrice != null) ...[
              FilterChipWidget(
                label: _priceFilterLabel,
                isSelected: true,
                onTap: _onFilterTap,
                onRemove: _clearPriceFilter,
              ),
              const SizedBox(width: 8),
            ],
            if (_activePropertyType != null) ...[
              FilterChipWidget(
                label: _propertyTypeLabel(_activePropertyType!),
                isSelected: true,
                onTap: _onFilterTap,
                onRemove: _clearPropertyTypeFilter,
              ),
              const SizedBox(width: 8),
            ],
            if (_activeBedrooms != null) ...[
              FilterChipWidget(
                label: '${_activeBedrooms!}+ Bedrooms',
                isSelected: true,
                onTap: _onFilterTap,
                onRemove: _clearBedroomsFilter,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasVisibleFilterChips =>
      _activeMinPrice != null ||
      _activeMaxPrice != null ||
      _activePropertyType != null ||
      _activeBedrooms != null;

  String get _priceFilterLabel {
    final min = _activeMinPrice?.toInt();
    final max = _activeMaxPrice?.toInt();
    if (min != null && max != null) return '\$$min - \$$max';
    if (min != null) return 'From \$$min';
    return 'Up to \$$max';
  }

  String _propertyTypeLabel(String propertyType) {
    switch (propertyType) {
      case 'for_rent':
        return 'For Rent';
      case 'for_sale':
        return 'For Sale';
      default:
        return 'House Type';
    }
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
            _toggleTab('Buy', _isBuy, () {
              setState(() => _isBuy = true);
              _reloadWithActiveFilters();
            }),
            _toggleTab('Rent', !_isBuy, () {
              setState(() => _isBuy = false);
              _reloadWithActiveFilters();
            }),
          ],
        ),
      ),
    );
  }

  Widget _toggleTab(String label, bool active, VoidCallback onTap) {
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
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
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

  Widget _buildFeaturedSection() {
    return BlocBuilder<PropertyBloc, PropertyState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Properties',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'See all',
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
            if (state is PropertyLoading)
              const SizedBox(
                height: 220,
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (state is PropertiesLoaded && state.properties.isNotEmpty)
              SizedBox(
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20),
                  itemCount: state.properties.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: FeaturedPropertyCard(
                        property: state.properties[index],
                        onTap: () {},
                        onFavTap: () {},
                      ),
                    );
                  },
                ),
              )
            else if (state is PropertiesLoaded && state.properties.isEmpty)
              const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No properties found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (state is PropertyError)
              SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNearbySection() {
    return BlocBuilder<PropertyBloc, PropertyState>(
      builder: (context, state) {
        if (state is! PropertiesLoaded) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nearby Your Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Explore Map',
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount:
                  state.properties.length > 5 ? 5 : state.properties.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NearbyPropertyCard(
                    property: state.properties[index],
                    onTap: () {},
                    onFavTap: () {},
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
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
    );
  }
}
