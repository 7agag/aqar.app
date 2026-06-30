import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aqar/core/extensions/num_formatting.dart';
import 'package:aqar/core/navigation/property_detail_navigator.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/favorite/presentation/bloc/favorite_bloc.dart';
import 'package:aqar/features/property/presentation/bloc/property_bloc.dart';
import 'package:aqar/features/property/presentation/bloc/property_event.dart';
import 'package:aqar/features/property/presentation/bloc/property_state.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/features/property/domain/entities/property_enums.dart';
import 'package:aqar/features/property/domain/entities/property_filter_params.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/price_pill_marker.dart';
import '../widgets/cluster_marker.dart';
import '../widgets/property_info_window.dart';

import '../widgets/map_bottom_sheet.dart';
import '../widgets/map_filter_bar.dart';
import '../../../../core/widgets/compass_needle.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final _mapController = MapController();
  PropertyEntity? _selectedProperty;
  bool _showSheet = false;
  String _searchQuery = '';
  MapFilter _filter = MapFilter.all;
  List<PropertyEntity> _allProperties = [];
  Position? _userPosition;
  Timer? _clusterDebounce;
  double _currentZoom = 12;
  double _bearing = 0;
  bool _locating = false;

  static const _cairoCenter = LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _clusterDebounce?.cancel();
    super.dispose();
  }

  void _initData() {
    final bloc = context.read<PropertyBloc>();
    if (bloc.state is! PropertiesLoaded) {
      bloc.add(GetPropertiesRequested(params: const PropertyFilterParams()));
    }
    context.read<FavoriteBloc>().add(GetFavoritesEvent());
  }

  List<PropertyEntity> get _filteredProperties {
    var props = _allProperties
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      props = props
          .where((p) =>
              p.propertyName.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q))
          .toList();
    }
    if (_filter == MapFilter.forRent) {
      props = props.where((p) => p.listingType == ListingType.forRent).toList();
    } else if (_filter == MapFilter.forSale) {
      props = props.where((p) => p.listingType == ListingType.forSale).toList();
    }
    return props;
  }

  List<Marker> _buildMarkers() {
    final props = _filteredProperties;
    if (props.isEmpty) return [];

    if (_currentZoom < 13) {
      return _buildClusters(props);
    }
    return props.map((p) => _singleMarker(p)).toList();
  }

  List<Marker> _buildClusters(List<PropertyEntity> props) {
    final gridSize = 0.015;
    final Map<String, List<PropertyEntity>> grid = {};

    for (final p in props) {
      final key =
          '${(p.latitude! / gridSize).floor()}:${(p.longitude! / gridSize).floor()}';
      grid.putIfAbsent(key, () => []);
      grid[key]!.add(p);
    }

    final markers = <Marker>[];
    for (final entry in grid.entries) {
      final group = entry.value;
      if (group.length == 1) {
        markers.add(_singleMarker(group.first));
      } else {
        final centerLat = group.map((p) => p.latitude!).reduce((a, b) => a + b) /
            group.length;
        final centerLng =
            group.map((p) => p.longitude!).reduce((a, b) => a + b) /
                group.length;
        markers.add(Marker(
          point: LatLng(centerLat, centerLng),
          width: 44,
          height: 44,
          child: ClusterMarker(
            count: group.length,
            onTap: () {
              _mapController.move(
                LatLng(centerLat, centerLng),
                _currentZoom + 1.5,
              );
            },
          ),
        ));
      }
    }
    return markers;
  }

  Marker _singleMarker(PropertyEntity p) {
    final isSelected = _selectedProperty?.propertyId == p.propertyId;
    return Marker(
      point: LatLng(p.latitude!, p.longitude!),
      width: isSelected ? 60 : 90,
      height: isSelected ? 60 : 40,
      child: isSelected
          ? const SizedBox.shrink()
          : PricePillMarker(
              priceValue: p.priceValue.toInt(),
              type: p.listingType,
              isSelected: false,
              onTap: () => _selectProperty(p),
            ),
    );
  }

  void _selectProperty(PropertyEntity p) {
    _mapController.move(LatLng(p.latitude!, p.longitude!), 15);
    setState(() {
      _selectedProperty = p;
      _showSheet = false;
    });
  }

  void _deselectProperty() {
    setState(() {
      _selectedProperty = null;
      _showSheet = false;
    });
  }

  String? _distanceText(PropertyEntity p) {
    if (_userPosition == null) return null;
    final dist = _haversine(
      _userPosition!.latitude,
      _userPosition!.longitude,
      p.latitude ?? 0,
      p.longitude ?? 0,
    );
    if (dist < 1) {
      return '${(dist * 1000).toStringAsFixed(0)} m away';
    }
    return '${dist.toStringAsFixed(1)} km away';
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _userPosition = pos;
        _locating = false;
      });
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location')),
      );
    }
  }

  Future<void> _resetToNorth() async {
    final start = _mapController.camera.rotation;
    if (start == 0) return;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final animation = Tween(begin: start, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
    controller.addListener(() {
      _mapController.rotate(animation.value);
    });
    controller.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (mounted) setState(() => _bearing = 0);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PropertyBloc, PropertyState>(
          listener: (context, state) {
            if (state is PropertiesLoaded && mounted) {
              setState(() => _allProperties = state.allProperties);
            }
          },
        ),
        BlocListener<FavoriteBloc, FavoriteState>(
          listener: (context, state) {},
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _cairoCenter,
                initialZoom: 12,
                onTap: (_, __) {
                  if (_selectedProperty != null) _deselectProperty();
                },
                onMapEvent: (event) {
                  if (event is MapEventMoveEnd) {
                    _clusterDebounce?.cancel();
                    _clusterDebounce =
                        Timer(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(() {
                          _currentZoom =
                              _mapController.camera.zoom;
                        });
                      }
                    });
                  }
                  if (event is MapEventRotateEnd) {
                    setState(() {
                      _bearing = _mapController.camera.rotation;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.aqar.app',
                ),
                MarkerLayer(
                  markers: _buildMarkers(),
                ),
                if (_userPosition != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(_userPosition!.latitude,
                            _userPosition!.longitude),
                        color: Colors.blue.withValues(alpha: 0.06),
                        borderColor: Colors.blue.withValues(alpha: 0.15),
                        borderStrokeWidth: 1.0,
                        radius: min(_userPosition!.accuracy, 25.0),
                        useRadiusInMeter: true,
                      ),
                    ],
                  ),
                if (_selectedProperty != null &&
                    _selectedProperty!.latitude != null &&
                    _selectedProperty!.longitude != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_selectedProperty!.latitude!,
                            _selectedProperty!.longitude!),
                        width: 260,
                        height: 290,
                        child: PropertyInfoWindow(
                          property: _selectedProperty!,
                          onViewDetails: () {
                            propertyDetailNavigator.value =
                                _selectedProperty!.propertyId;
                            setState(() => _showSheet = true);
                          },
                          onClose: _deselectProperty,
                        ),
                      ),
                    ],
                  ),
                if (_userPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_userPosition!.latitude,
                            _userPosition!.longitude),
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4285F4)
                                    .withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: Offset.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
            if (_selectedProperty != null && _showSheet)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: MapBottomSheet(
                  property: _selectedProperty!,
                  distanceText: _distanceText(_selectedProperty!),
                  onViewDetails: () =>
                      propertyDetailNavigator.value =
                          _selectedProperty!.propertyId,
                ),
              ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom +
                  (_selectedProperty != null ? 220 : 24),
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: _selectedProperty != null,
                child: AnimatedOpacity(
                  opacity: _selectedProperty != null ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: MapFilterBar(
                    selected: _filter,
                    onChanged: (f) => setState(() {
                      _filter = f;
                      _selectedProperty = null;
                    }),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom +
                  (_selectedProperty != null ? 220 : 80),
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'locate',
                    onPressed: _locating ? null : _locateMe,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.navyBlue,
                    elevation: 2,
                    child: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, size: 20),
                  ),
                  Opacity(
                    opacity: _bearing.abs() <= 3 ? 0.35 : 1.0,
                    child: FloatingActionButton.small(
                      heroTag: 'north',
                      onPressed: _resetToNorth,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.navyBlue,
                      elevation: 2,
                      child: CompassNeedle(rotation: _bearing),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    onPressed: () =>
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        ),
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.navyBlue,
                    elevation: 2,
                    child: const Icon(Icons.add, size: 20),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    onPressed: () =>
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        ),
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.navyBlue,
                    elevation: 2,
                    child: const Icon(Icons.remove, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                      fontSize: 14, color: AppColors.textHint),
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
                      color: (isRent ? AppColors.success : AppColors.navyBlue)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRent ? Icons.home_rounded : Icons.apartment_rounded,
                      size: 18,
                      color: isRent ? AppColors.success : AppColors.navyBlue,
                    ),
                  ),
                  title: Text(
                    p.propertyName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(p.location,
                      style: const TextStyle(fontSize: 11), maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    '${p.priceValue.formatWithCommas()} EGP',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyBlue),
                  ),
                  onTap: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedProperty = p;
                    });
                    _mapController.move(
                        LatLng(p.latitude!, p.longitude!), 15);
                  },
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 0),
                );
              },
            ),
    );
  }
}
