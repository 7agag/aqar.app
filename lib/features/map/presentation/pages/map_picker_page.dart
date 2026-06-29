import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/theme/app_spacing.dart';

class MapPickerResult {
  final double lat;
  final double lng;
  final String address;
  const MapPickerResult({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class MapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const MapPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage>
    with SingleTickerProviderStateMixin {
  late final MapController _mapCtrl;
  static const _cairoCenter = LatLng(30.0444, 31.2357);

  double _displayLat = 30.0444;
  double _displayLng = 31.2357;
  double _displayZoom = 14;
  double? _lat, _lng;
  String _resolvedAddress = '';
  bool _locationConfirmed = false;
  bool _isGeocoding = false;
  bool _isLocating = false;
  double? _gpsAccuracy;
  LatLng? _gpsPosition;
  Marker? _fineTuneMarker;
  Timer? _geocodeDebounce;
  late AnimationController _pulseCtrl;
  bool _entrancePlayed = false;

  final _searchCtl = TextEditingController();
  List<_SearchResult> _searchResults = [];
  Timer? _searchDebounce;

  bool _showManualFallback = false;
  final _streetCtl = TextEditingController();
  final _districtCtl = TextEditingController();
  final _cityCtl = TextEditingController();
  final _govCtl = TextEditingController();

  final Dio _nomDio = Dio(BaseOptions(
    headers: {'User-Agent': 'AQAR/1.0'},
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.initialLat != null && widget.initialLng != null) {
      _displayLat = widget.initialLat!;
      _displayLng = widget.initialLng!;
      _lat = widget.initialLat!;
      _lng = widget.initialLng!;
      _locationConfirmed = true;
      _resolvedAddress = widget.initialAddress ?? '';
    }
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    _pulseCtrl.dispose();
    _geocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchCtl.dispose();
    _streetCtl.dispose();
    _districtCtl.dispose();
    _cityCtl.dispose();
    _govCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_entrancePlayed) {
      _entrancePlayed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
    }
    if (!_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📍 Location',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _lat != null
                  ? LatLng(_lat!, _lng!)
                  : _cairoCenter,
              initialZoom: _lat != null ? 17 : 14,
              minZoom: 3,
              maxZoom: 18,
              onMapEvent: _onMapEvent,
              onLongPress: (_, latlng) => _dropFineTuneMarker(latlng),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.aqar.app',
              ),
              if (_gpsPosition != null &&
                  _gpsAccuracy != null &&
                  _gpsAccuracy! > 0)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _gpsPosition!,
                      radius: _gpsAccuracy!,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderColor: AppColors.primary.withValues(alpha: 0.25),
                      borderStrokeWidth: 1.5,
                      useRadiusInMeter: true,
                    ),
                  ],
                ),
              if (_fineTuneMarker != null)
                MarkerLayer(markers: [_fineTuneMarker!]),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(child: _buildPulsingPin()),
            ),
          ),
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: _buildSearchDropdown(),
            ),
          Positioned(
            top: 8,
            right: 16,
            child: _buildPrecisionBadge(),
          ),
          Positioned(
            top: 62,
            left: 16,
            child: _buildCoordinateChip(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingPin() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final scale = 1.0 + (_pulseCtrl.value * 0.15);
        final ringOpacity = 0.3 - (_pulseCtrl.value * 0.25);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 64 * scale,
              height: 64 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: ringOpacity),
              ),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Icon(Icons.location_on_rounded,
                size: 44, color: AppColors.primary),
          ],
        );
      },
    );
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd) {
      final center = _mapCtrl.camera.center;
      final zoom = _mapCtrl.camera.zoom;
      setState(() {
        _displayLat = center.latitude;
        _displayLng = center.longitude;
        _displayZoom = zoom;
        if (_locationConfirmed) {
          final dist = _distanceBetween(
              _lat!, _lng!, center.latitude, center.longitude);
          if (dist > 100) _locationConfirmed = false;
        }
      });
      _geocodeDebounce?.cancel();
      _geocodeDebounce = Timer(
          const Duration(milliseconds: 800), () => _autoGeocode());
    }
  }

  double _distanceBetween(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLng = (lng2 - lng1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  void _dropFineTuneMarker(LatLng latlng) {
    HapticFeedback.heavyImpact();
    setState(() {
      _fineTuneMarker = Marker(
        point: latlng,
        width: 40,
        height: 48,
        child: const Icon(Icons.location_on,
            size: 38, color: Color(0xFFE65100)),
      );
      _displayLat = latlng.latitude;
      _displayLng = latlng.longitude;
    });
    _mapCtrl.move(latlng, _mapCtrl.camera.zoom);
    _geocodeDebounce?.cancel();
    _geocodeDebounce =
        Timer(const Duration(milliseconds: 800), () => _autoGeocode());
  }

  Future<void> _autoGeocode() async {
    setState(() => _isGeocoding = true);
    try {
      final response = await _nomDio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': _displayLat.toStringAsFixed(6),
          'lon': _displayLng.toStringAsFixed(6),
          'accept-language': 'en',
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final addr = response.data['address'] as Map? ?? {};
        final parts = [
          _nonNull(addr['suburb']),
          _nonNull(addr['city_district']),
          _nonNull(addr['city']),
          _nonNull(addr['town']),
          _nonNull(addr['village']),
          _nonNull(addr['state']),
          _nonNull(addr['country']),
        ];
        setState(() {
          _resolvedAddress = parts.where((e) => e.isNotEmpty).join(', ');
        });
      }
    } catch (_) {
    } finally {
      setState(() => _isGeocoding = false);
    }
  }

  Future<void> _confirmLocation() async {
    if (_resolvedAddress.isEmpty) {
      await _autoGeocode();
    }
    if (_resolvedAddress.isEmpty && !_showManualFallback) {
      setState(() => _showManualFallback = true);
      return;
    }
    if (_resolvedAddress.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not resolve address. Fill the fields below.'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _lat = _displayLat;
      _lng = _displayLng;
      _locationConfirmed = true;
    });
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, value, __) => Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 4),
                ],
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 64, color: AppColors.success),
            ),
          ),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _done() {
    if (_lat == null || _lng == null) return;
    Navigator.pop(
      context,
      MapPickerResult(
        lat: _lat!,
        lng: _lng!,
        address: _resolvedAddress,
      ),
    );
  }

  Future<void> _locateMe() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permission denied. Please pan the map manually.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _gpsPosition = LatLng(pos.latitude, pos.longitude);
        _gpsAccuracy = pos.accuracy;
        _displayLat = pos.latitude;
        _displayLng = pos.longitude;
      });
      _animatedFlyTo(LatLng(pos.latitude, pos.longitude), 17);
      _geocodeDebounce?.cancel();
      _geocodeDebounce =
          Timer(const Duration(milliseconds: 800), () => _autoGeocode());
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('GPS timed out. Pan the map manually.'),
            backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('GPS unavailable. Pan the map manually.'),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _animatedFlyTo(LatLng target, double zoom) {
    final start = _mapCtrl.camera.center;
    final startZoom = _mapCtrl.camera.zoom;
    const steps = 20;
    var step = 0;
    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      step++;
      final t = step / steps;
      final lat = start.latitude + (target.latitude - start.latitude) * t;
      final lng = start.longitude + (target.longitude - start.longitude) * t;
      final z = startZoom + (zoom - startZoom) * t;
      _mapCtrl.move(LatLng(lat, lng), z);
      if (step >= steps) timer.cancel();
    });
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchCtl,
        onChanged: (q) {
          _searchDebounce?.cancel();
          if (q.trim().length < 3) {
            setState(() => _searchResults = []);
            return;
          }
          _searchDebounce = Timer(
              const Duration(milliseconds: 500), () => _searchNominatim(q));
        },
        decoration: InputDecoration(
          hintText: 'Search area or district…',
          hintStyle:
              const TextStyle(fontSize: 14, color: AppColors.textHint),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textHint, size: 22),
          suffixIcon: Icon(Icons.explore_outlined,
              color: AppColors.primary, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Future<void> _searchNominatim(String query) async {
    try {
      final response = await _nomDio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
          'accept-language': 'en',
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          _searchResults = (response.data as List)
              .map((e) => _SearchResult(
                    displayName: e['display_name']?.toString() ?? '',
                    lat: double.tryParse(e['lat']?.toString() ?? '') ?? 0,
                    lon: double.tryParse(e['lon']?.toString() ?? '') ?? 0,
                  ))
              .toList();
        });
      }
    } catch (_) {
    }
  }

  Widget _buildSearchDropdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (_, i) {
          final r = _searchResults[i];
          return ListTile(
            dense: true,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on,
                  size: 18, color: AppColors.primary),
            ),
            title: Text(r.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${r.lat.toStringAsFixed(4)}, ${r.lon.toStringAsFixed(4)}',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textHint)),
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _searchResults = [];
                _searchCtl.clear();
                _displayLat = r.lat;
                _displayLng = r.lon;
              });
              _animatedFlyTo(LatLng(r.lat, r.lon), 17);
              _geocodeDebounce?.cancel();
              _geocodeDebounce = Timer(
                  const Duration(milliseconds: 800), () => _autoGeocode());
            },
          );
        },
      ),
    );
  }

  Widget _buildPrecisionBadge() {
    String label;
    if (_displayZoom >= 16) {
      label = '🎯 Street level';
    } else if (_displayZoom >= 13) {
      label = '📍 Area level';
    } else {
      label = '🌍 City level';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _mapCtrl.move(_mapCtrl.camera.center,
                (_mapCtrl.camera.zoom + 1).clamp(3, 18)),
            child:
                const Icon(Icons.add, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gps_fixed, size: 12, color: AppColors.navyBlue),
          const SizedBox(width: 4),
          Text(
            '${_displayLat.toStringAsFixed(4)}, ${_displayLng.toStringAsFixed(4)}',
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.navyBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gps_fixed,
                    size: 14,
                    color: _locationConfirmed
                        ? AppColors.success
                        : AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '${_displayLat.toStringAsFixed(4)}, ${_displayLng.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _locationConfirmed
                        ? AppColors.success
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_locationConfirmed)
              _buildConfirmedCard()
            else if (_showManualFallback)
              _buildManualFallbackForm()
            else
              _buildActionRow(),
            if (_locationConfirmed)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _done,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd)),
                      elevation: 0,
                    ),
                    child: const Text('Done',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Location Verified',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
                Text(_resolvedAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _isLocating ? null : _locateMe,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(_isLocating ? 'Locating…' : 'Locate Me',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyBlue,
                    side: const BorderSide(color: AppColors.navyBlue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isGeocoding ? null : _confirmLocation,
                  icon: _isGeocoding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 18),
                  label: Text(_isGeocoding ? 'Resolving…' : 'Confirm',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!_locationConfirmed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Long-press the map to fine-tune the pin position',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint.withValues(alpha: 0.8)),
            ),
          ),
      ],
    );
  }

  Widget _buildManualFallbackForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_location_alt,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Enter address manually',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _manualField('Street', _streetCtl),
        const SizedBox(height: AppSpacing.xs),
        _manualField('District', _districtCtl),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(child: _manualField('City', _cityCtl)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _manualField('Governorate', _govCtl)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            onPressed: () {
              final parts = [
                _streetCtl.text.trim(),
                _districtCtl.text.trim(),
                _cityCtl.text.trim(),
                _govCtl.text.trim(),
              ].where((e) => e.isNotEmpty);
              if (parts.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Enter at least District and City')),
                );
                return;
              }
              HapticFeedback.mediumImpact();
              setState(() {
                _resolvedAddress = parts.join(', ');
                _lat = _displayLat;
                _lng = _displayLng;
                _locationConfirmed = true;
                _showManualFallback = false;
              });
              _showSuccessDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm)),
              elevation: 0,
            ),
            child: const Text('Apply Address',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _manualField(String label, TextEditingController ctl) {
    return TextField(
      controller: ctl,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }

  String _nonNull(dynamic v) => v?.toString().trim() ?? '';
}

class _SearchResult {
  final String displayName;
  final double lat;
  final double lon;
  const _SearchResult(
      {required this.displayName, required this.lat, required this.lon});
}
