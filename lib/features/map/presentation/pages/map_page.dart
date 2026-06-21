import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:aqar/core/navigation/property_detail_navigator.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/features/property/domain/entities/property_enums.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/property_bottom_card.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapController = MapController();
  PropertyEntity? _selectedProperty;
  String _searchQuery = '';

  static const _cairoCenter = LatLng(30.0444, 31.2357);

  late final List<PropertyEntity> _properties;

  @override
  void initState() {
    super.initState();
    _properties = _initProperties();
  }

  List<PropertyEntity> _initProperties() {
    return [
      PropertyEntity(
        propertyId: 1,
        ownerId: 'owner1',
        propertyName: 'Luxury Villa in Zamalek',
        propertyDesc: 'Elegant villa with Nile view in the heart of Zamalek.',
        location: 'Zamalek, Cairo',
        latitude: 30.065,
        longitude: 31.219,
        pricingUnit: PricingUnit.month,
        priceValue: 2500000,
        pricePerDay: 0,
        size: '450 m\u00B2',
        bedroomsNo: 5,
        bedsNo: 6,
        bathroomsNo: 4,
        images: [],
        isVerified: true,
        isAvailable: true,
        isFurnished: true,
        listingType: ListingType.forSale,
      ),
      PropertyEntity(
        propertyId: 2,
        ownerId: 'owner2',
        propertyName: 'Modern Apartment in New Cairo',
        propertyDesc: 'Spacious modern apartment in a prime location.',
        location: 'New Cairo, Cairo',
        latitude: 30.011,
        longitude: 31.416,
        pricingUnit: PricingUnit.month,
        priceValue: 15000,
        pricePerDay: 0,
        size: '180 m\u00B2',
        bedroomsNo: 3,
        bedsNo: 3,
        bathroomsNo: 2,
        images: [],
        isVerified: true,
        isAvailable: true,
        isFurnished: true,
        listingType: ListingType.forRent,
      ),
      PropertyEntity(
        propertyId: 3,
        ownerId: 'owner3',
        propertyName: 'Classic Apartment in Maadi',
        propertyDesc: 'Charming apartment in the leafy suburb of Maadi.',
        location: 'Maadi, Cairo',
        latitude: 29.970,
        longitude: 31.254,
        pricingUnit: PricingUnit.month,
        priceValue: 1800000,
        pricePerDay: 0,
        size: '200 m\u00B2',
        bedroomsNo: 4,
        bedsNo: 4,
        bathroomsNo: 2,
        images: [],
        isVerified: true,
        isAvailable: true,
        isFurnished: false,
        listingType: ListingType.forSale,
      ),
      PropertyEntity(
        propertyId: 4,
        ownerId: 'owner4',
        propertyName: 'Spacious Villa in Sheikh Zayed',
        propertyDesc: 'Large family villa with garden in Sheikh Zayed.',
        location: 'Sheikh Zayed, Giza',
        latitude: 30.026,
        longitude: 30.996,
        pricingUnit: PricingUnit.month,
        priceValue: 35000,
        pricePerDay: 0,
        size: '350 m\u00B2',
        bedroomsNo: 5,
        bedsNo: 5,
        bathroomsNo: 4,
        images: [],
        isVerified: true,
        isAvailable: true,
        isFurnished: true,
        listingType: ListingType.forRent,
      ),
      PropertyEntity(
        propertyId: 5,
        ownerId: 'owner5',
        propertyName: 'Cozy Studio Downtown',
        propertyDesc: 'Compact studio in the vibrant downtown area.',
        location: 'Downtown, Cairo',
        latitude: 30.047,
        longitude: 31.237,
        pricingUnit: PricingUnit.month,
        priceValue: 850000,
        pricePerDay: 0,
        size: '55 m\u00B2',
        bedroomsNo: 1,
        bedsNo: 1,
        bathroomsNo: 1,
        images: [],
        isVerified: false,
        isAvailable: true,
        isFurnished: true,
        listingType: ListingType.forSale,
      ),
      PropertyEntity(
        propertyId: 6,
        ownerId: 'owner6',
        propertyName: 'Family Apartment in Nasr City',
        propertyDesc: 'Well-maintained apartment near all amenities.',
        location: 'Nasr City, Cairo',
        latitude: 30.055,
        longitude: 31.330,
        pricingUnit: PricingUnit.month,
        priceValue: 12000,
        pricePerDay: 0,
        size: '160 m\u00B2',
        bedroomsNo: 3,
        bedsNo: 3,
        bathroomsNo: 2,
        images: [],
        isVerified: true,
        isAvailable: true,
        isFurnished: true,
        listingType: ListingType.forRent,
      ),
      PropertyEntity(
        propertyId: 7,
        ownerId: 'owner7',
        propertyName: 'Elegant Villa in Heliopolis',
        propertyDesc: 'Stunning villa with pool in the prestigious Heliopolis district.',
        location: 'Heliopolis, Cairo',
        latitude: 30.090,
        longitude: 31.329,
        pricingUnit: PricingUnit.month,
        priceValue: 3200000,
        pricePerDay: 0,
        size: '500 m\u00B2',
        bedroomsNo: 6,
        bedsNo: 6,
        bathroomsNo: 5,
        images: [],
        isVerified: true,
        isAvailable: true,
        isFurnished: true,
        listingType: ListingType.forSale,
      ),
      PropertyEntity(
        propertyId: 8,
        ownerId: 'owner8',
        propertyName: 'Stylish Apt in Mohandeseen',
        propertyDesc: 'Modern apartment close to shops and restaurants.',
        location: 'Mohandeseen, Giza',
        latitude: 30.055,
        longitude: 31.200,
        pricingUnit: PricingUnit.month,
        priceValue: 18000,
        pricePerDay: 0,
        size: '140 m\u00B2',
        bedroomsNo: 2,
        bedsNo: 2,
        bathroomsNo: 2,
        images: [],
        isVerified: true,
        isAvailable: true,
        isFurnished: true,
        listingType: ListingType.forRent,
      ),
    ];
  }

  List<PropertyEntity> get _filteredProperties {
    if (_searchQuery.isEmpty) return _properties;
    final query = _searchQuery.toLowerCase();
    return _properties.where((p) {
      return p.propertyName.toLowerCase().contains(query) ||
          p.location.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _cairoCenter,
              initialZoom: 12,
              onTap: (_, __) {
                if (_selectedProperty != null) {
                  setState(() => _selectedProperty = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: MapSearchBar(
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 74,
              left: 16,
              right: 16,
              child: _buildSearchDropdown(),
            ),
          if (_selectedProperty != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: PropertyBottomCard(
                property: _selectedProperty!,
                onTap: () =>
                    propertyDetailNavigator.value = _selectedProperty!.propertyId,
              ),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _filteredProperties
        .where((p) => p.latitude != null && p.longitude != null)
        .map((p) {
      final isRent = p.listingType == ListingType.forRent;
      final isSelected = _selectedProperty?.propertyId == p.propertyId;

      return Marker(
        point: LatLng(p.latitude!, p.longitude!),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () {
            _mapController.move(LatLng(p.latitude!, p.longitude!), 15);
            setState(() => _selectedProperty = p);
          },
          child: _markerIcon(isRent, isSelected),
        ),
      );
    }).toList();
  }

  Widget _markerIcon(bool isRent, bool isSelected) {
    final color = isRent ? AppColors.navyBlue : Colors.red;
    final size = isSelected ? 44.0 : 36.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isRent ? Icons.home_rounded : Icons.apartment_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildSearchDropdown() {
    final results = _filteredProperties;

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: results.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No results found',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: results.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (_, i) {
                final p = results[i];
                final isRent = p.listingType == ListingType.forRent;
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (isRent ? AppColors.navyBlue : Colors.red)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRent ? Icons.home_rounded : Icons.apartment_rounded,
                      size: 18,
                      color: isRent ? AppColors.navyBlue : Colors.red,
                    ),
                  ),
                  title: Text(
                    p.propertyName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    p.location,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${p.priceValue.toStringAsFixed(0)} EGP',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyBlue,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedProperty = p;
                    });
                    _mapController.move(
                        LatLng(p.latitude!, p.longitude!), 15);
                  },
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                );
              },
            ),
    );
  }
}
