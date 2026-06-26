import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aqar/features/payment/domain/usecases/get_payment_link_usecase.dart';
import 'package:aqar/features/payment/presentation/pages/kashier_web_view_page.dart';
import 'package:aqar/features/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/theme/app_spacing.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/features/property/domain/entities/property_enums.dart';
import 'package:aqar/core/services/biometric_auth_guard.dart';
import 'package:aqar/features/property/presentation/widgets/photo_tips_card.dart';
import 'package:aqar/injection_container.dart' as di;

class AddPropertyStepperPage extends StatefulWidget {
  const AddPropertyStepperPage({super.key});

  @override
  State<AddPropertyStepperPage> createState() => _AddPropertyStepperPageState();
}

class _AddPropertyStepperPageState extends State<AddPropertyStepperPage>
    with SingleTickerProviderStateMixin {
  // -- Navigation --
  int _currentStep = 0;
  late final PageController _pageCtrl;
  bool _isSubmitting = false;
  bool _isSubmittingProperty = false;

  // -- Step 0: Basic Info --
  final _basicKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  bool _isForRent = true;
  bool _isFurnished = false;
  RentPeriod _rentPeriod = RentPeriod.monthly;
  final _priceCtl = TextEditingController();
  final _sizeCtl = TextEditingController();
  final _bedsCtl = TextEditingController();
  final _bathroomsCtl = TextEditingController();
  final _bedroomsCtl = TextEditingController();

  // -- Step 3: Map Location --
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
  bool _entrancePlayed = false;
  late AnimationController _pulseCtrl;

  // -- Search --
  final _searchCtl = TextEditingController();
  List<_SearchResult> _searchResults = [];
  Timer? _searchDebounce;

  // -- Fallback manual --
  bool _showManualFallback = false;
  final _streetCtl = TextEditingController();
  final _districtCtl = TextEditingController();
  final _cityCtl = TextEditingController();
  final _govCtl = TextEditingController();

  // -- Step 1: Media --
  final List<XFile> _propertyImages = [];

  // -- Step 2: Plan --
  int? _salePlanMonths;

  // -- Step 4: Documents --
  XFile? _govIdDoc;
  XFile? _ownershipDoc;
  final List<XFile> _supportingDocs = [];

  // -- Nomintim Dio --
  final Dio _nomDio = Dio(BaseOptions(
    headers: {'User-Agent': 'AQAR/1.0'},
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  // ---------------------------------------------------------------------------
  // INIT / DISPOSE
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _mapCtrl = MapController();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _mapCtrl.dispose();
    _pulseCtrl.dispose();
    _geocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchCtl.dispose();
    _streetCtl.dispose();
    _districtCtl.dispose();
    _cityCtl.dispose();
    _govCtl.dispose();
    _titleCtl.dispose();
    _descCtl.dispose();
    _priceCtl.dispose();
    _sizeCtl.dispose();
    _bedsCtl.dispose();
    _bathroomsCtl.dispose();
    _bedroomsCtl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_currentStep == 3 && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (_currentStep != 3 && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentStep == 3 ? '📍 Location' : 'Add Property',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary),
        ),
        backgroundColor: _currentStep == 3 ? Colors.transparent : Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: _currentStep == 3 ? 0 : 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _currentStep == 0
              ? () => Navigator.pop(context)
              : () => _goToStep(_currentStep - 1),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: _stepPages,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> get _stepPages {
    return [
      _buildBasicInfoStep(),
      _buildMediaStep(),
      _buildPlanStep(),
      _buildMapStep(),
      _buildDocumentsStep(),
      if (!_isForRent) _buildInvoiceStep(),
    ];
  }

  // ---------------------------------------------------------------------------
  // STEP INDICATOR
  // ---------------------------------------------------------------------------
  Widget _buildStepIndicator() {
    final rentLabels = ['Basic', 'Media', 'Plan', 'Map', 'Docs'];
    final saleLabels = ['Basic', 'Media', 'Plan', 'Map', 'Docs', 'Invoice'];
    final rentIcons = [
      Icons.edit_note,
      Icons.image,
      Icons.sell,
      Icons.location_on,
      Icons.verified_outlined
    ];
    final saleIcons = [
      Icons.edit_note,
      Icons.image,
      Icons.sell,
      Icons.location_on,
      Icons.verified_outlined,
      Icons.receipt_long
    ];
    final labels = _isForRent ? rentLabels : saleLabels;
    final icons = _isForRent ? rentIcons : saleIcons;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.md),
      color: Colors.white,
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? AppColors.primary : AppColors.borderLight,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone || isActive
                            ? AppColors.primary
                            : AppColors.surfaceLight,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : Icon(icons[i],
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textHint,
                                size: 16),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: BASIC INFO  (location field removed)
  // ---------------------------------------------------------------------------
  Widget _buildBasicInfoStep() {
    return Form(
      key: _basicKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildLabel('Property Title *'),
          _buildTextField(_titleCtl, 'e.g. Modern Apartment in New Cairo',
              validator: (v) {
            if (v == null || v.trim().length < 3) {
              return 'Title must be at least 3 characters';
            }
            return null;
          }),
          const SizedBox(height: AppSpacing.md),
          _buildLabel('Description *'),
          TextFormField(
            controller: _descCtl,
            maxLines: 4,
            validator: (v) => v == null || v.trim().length < 10
                ? 'Description must be at least 10 characters'
                : null,
            decoration:
                _inputDecoration(hint: 'Describe your property in detail...'),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildLabel('Listing Type *'),
          ToggleButtons(
            isSelected: [_isForRent, !_isForRent],
            onPressed: (i) {
              if (_currentStep > 0) {
                _pageCtrl.animateToPage(0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
              }
              setState(() {
                _isForRent = i == 0;
                _salePlanMonths = null;
                _lat = null;
                _lng = null;
                _resolvedAddress = '';
                _locationConfirmed = false;
                _govIdDoc = null;
                _ownershipDoc = null;
                _supportingDocs.clear();
              });
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            selectedColor: Colors.white,
            fillColor: AppColors.primary,
            color: AppColors.textPrimary,
            constraints: const BoxConstraints(minWidth: 100, minHeight: 44),
            children: const [Text('For Rent'), Text('For Sale')],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildLabel('Price *'),
          _buildTextField(_priceCtl, _isForRent ? 'e.g. 15000' : 'e.g. 5000000',
              keyboardType: TextInputType.number, validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Price is required';
            if (double.tryParse(v.trim()) == null ||
                double.parse(v.trim()) <= 0) {
              return 'Enter a valid price';
            }
            if (double.parse(v.trim()) > 99999999) {
              return 'Max price is 99,999,999 EGP';
            }
            return null;
          }),
          const SizedBox(height: AppSpacing.md),
          _buildLabel('Size (m\u00B2) *'),
          _buildTextField(_sizeCtl, 'e.g. 150',
              keyboardType: TextInputType.number, validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Size is required';
            return null;
          }),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _buildFieldGroup('Bedrooms', _bedroomsCtl)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildFieldGroup('Beds', _bedsCtl)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildFieldGroup('Bathrooms', _bathroomsCtl)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: _isFurnished,
            onChanged: (v) => setState(() => _isFurnished = v),
            title: const Text('Furnished / مفروشة',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          if (_isForRent) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildLabel('Rental Period *'),
            Row(
              children: [
                Expanded(
                  child: _rentPeriodRadio(RentPeriod.daily),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _rentPeriodRadio(RentPeriod.monthly),
                ),
              ],
            ),
          ],
          if (_resolvedAddress.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '📍 $_resolvedAddress',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _buildNavButtons(
            onNext: () {
              if (_basicKey.currentState!.validate()) _goToStep(1);
            },
            nextLabel: 'Next — Media',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: MAP LOCATION
  // ---------------------------------------------------------------------------
  Widget _buildMapStep() {
    if (!_entrancePlayed) {
      _entrancePlayed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
    }
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _cairoCenter,
            initialZoom: 14,
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

        // Center pulse pin
        Positioned.fill(
          child: IgnorePointer(
            child: Center(child: _buildPulsingPin()),
          ),
        ),

        // Search bar
        Positioned(
          top: 8,
          left: 16,
          right: 16,
          child: _buildSearchBar(),
        ),

        // Search dropdown
        if (_searchResults.isNotEmpty)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: _buildSearchDropdown(),
          ),

        // Precision badge
        Positioned(
          top: 8,
          right: 16,
          child: _buildPrecisionBadge(),
        ),

        // Coordinate readout mini chip (top-left / below search)
        Positioned(
          top: 62,
          left: 16,
          child: _buildCoordinateChip(),
        ),

        // Bottom card
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildMapBottomCard(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MAP: Pulsing center pin
  // ---------------------------------------------------------------------------
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
            Icon(Icons.location_on_rounded, size: 44, color: AppColors.primary),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MAP: Event handler
  // ---------------------------------------------------------------------------
  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd) {
      final center = _mapCtrl.camera.center;
      final zoom = _mapCtrl.camera.zoom;
      setState(() {
        _displayLat = center.latitude;
        _displayLng = center.longitude;
        _displayZoom = zoom;
        if (_locationConfirmed) {
          final dist =
              _distanceBetween(_lat!, _lng!, center.latitude, center.longitude);
          if (dist > 100) _locationConfirmed = false;
        }
      });
      _geocodeDebounce?.cancel();
      _geocodeDebounce =
          Timer(const Duration(milliseconds: 800), () => _autoGeocode());
    }
  }

  double _distanceBetween(double lat1, double lng1, double lat2, double lng2) {
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

  // ---------------------------------------------------------------------------
  // MAP: Fine-tune marker via long-press
  // ---------------------------------------------------------------------------
  void _dropFineTuneMarker(LatLng latlng) {
    HapticFeedback.heavyImpact();
    setState(() {
      _fineTuneMarker = Marker(
        point: latlng,
        width: 40,
        height: 48,
        child:
            const Icon(Icons.location_on, size: 38, color: Color(0xFFE65100)),
      );
      _displayLat = latlng.latitude;
      _displayLng = latlng.longitude;
    });
    _mapCtrl.move(latlng, _mapCtrl.camera.zoom);
    _geocodeDebounce?.cancel();
    _geocodeDebounce =
        Timer(const Duration(milliseconds: 800), () => _autoGeocode());
  }

  // ---------------------------------------------------------------------------
  // MAP: Auto-reverse geocode (Nominatim)
  // ---------------------------------------------------------------------------
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
      // silent — fallback on manual confirm
    } finally {
      setState(() => _isGeocoding = false);
    }
  }

  // ---------------------------------------------------------------------------
  // MAP: Confirm location
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // MAP: GPS Locate Me
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // MAP: Search bar
  // ---------------------------------------------------------------------------
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
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textHint, size: 22),
          suffixIcon:
              Icon(Icons.explore_outlined, color: AppColors.primary, size: 20),
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
      // silent
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
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

  // ---------------------------------------------------------------------------
  // MAP: Precision badge
  // ---------------------------------------------------------------------------
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
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
            child: const Icon(Icons.add, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAP: Coordinate chip
  // ---------------------------------------------------------------------------
  Widget _buildCoordinateChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
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

  // ---------------------------------------------------------------------------
  // MAP: Bottom card
  // ---------------------------------------------------------------------------
  Widget _buildMapBottomCard() {
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
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Coordinate row
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
                    onPressed: () => _goToStep(4),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd)),
                      elevation: 0,
                    ),
                    child: const Text('Next — Docs',
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
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
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
                        fontSize: 11, color: AppColors.textSecondary)),
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
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(_isLocating ? 'Locating…' : 'Locate Me',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyBlue,
                    side: const BorderSide(color: AppColors.navyBlue),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm)),
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
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm)),
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
                      content: Text('Enter at least District and City')),
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
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

  // ---------------------------------------------------------------------------
  // STEP 1: MEDIA  (photo tips, min 3, no ownership docs)
  // ---------------------------------------------------------------------------
  Widget _buildMediaStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PhotoTipsCard(),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            _buildLabel('Property Images * (3–10)'),
            const Spacer(),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildImageGrid(),
        if (_propertyImages.length < 3)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Minimum 3 images required (${_propertyImages.length}/3)',
              style: TextStyle(
                fontSize: 12,
                color: _propertyImages.isEmpty
                    ? AppColors.error
                    : AppColors.textHint,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        _buildNavButtons(
          onBack: () => _goToStep(0),
          onNext: () {
            if (_propertyImages.length < 3) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please add at least 3 property images'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
            _goToStep(2);
          },
          nextLabel: 'Next — Plan',
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return SizedBox(
      height: 100,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _propertyImages.length + (_propertyImages.length < 10 ? 1 : 0),
        onReorder: (oldI, newI) {
          setState(() {
            final item = _propertyImages.removeAt(oldI);
            _propertyImages.insert(newI, item);
          });
        },
        itemBuilder: (_, i) {
          if (i < _propertyImages.length) {
            return Padding(
              key: ValueKey(_propertyImages[i].path),
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: _buildImageThumb(i, _propertyImages[i]),
            );
          }
          return Padding(
            key: const ValueKey('add-image-button'),
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: AppColors.primary, size: 28),
                    SizedBox(height: 2),
                    Text('Add',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageThumb(int index, XFile file) {
    return GestureDetector(
      onTap: () => _showImagePreview(index),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              width: 90,
              height: 90,
              child: kIsWeb
                  ? _PickedImageTile(file: file)
                  : Image.file(File(file.path), fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 2,
            left: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () {
                setState(() => _propertyImages.removeAt(index));
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.error),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
              const SizedBox(height: 20),
              const Text('Add Photo',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _sourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      subtitle: 'Take a photo now',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickFromCamera();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _sourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      subtitle: 'Choose from library',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickFromGallery();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() {
        if (_propertyImages.length < 10) _propertyImages.add(file);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final files = await ImagePicker().pickMultiImage();
    if (files.isNotEmpty) {
      setState(() {
        for (final f in files) {
          if (_propertyImages.length < 10) _propertyImages.add(f);
        }
      });
    }
  }

  void _showImagePreview(int index) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImagePreview(
          images: _propertyImages,
          initialIndex: index,
        ),
      ),
    );
  }



  // ---------------------------------------------------------------------------
  // STEP 2: PLAN  (sale: 1/3/6 months at 120/360/600; rent: free)
  // ---------------------------------------------------------------------------
  Widget _buildPlanStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text(
          'Choose your listing plan',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _isForRent
              ? 'Rental listings are free. No additional cost.'
              : 'Sale listings require a paid plan. Choose a duration below.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_isForRent)
          _buildFreePlanCard()
        else ...[
          _buildSalePlanCard(
              1, '1 Month', 120, 'Standard visibility for 30 days'),
          const SizedBox(height: AppSpacing.md),
          _buildSalePlanCard(
              3, '3 Months', 360, 'Extended visibility with discounted rate'),
          const SizedBox(height: AppSpacing.md),
          _buildSalePlanCard(
              6, '6 Months', 600, 'Maximum exposure until sold — best value'),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (!_isForRent && _salePlanMonths == null)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text('Please select a plan to continue',
                style: TextStyle(fontSize: 12, color: AppColors.error)),
          ),
        _buildNavButtons(
          onBack: () => _goToStep(1),
          onNext: () {
            if (!_isForRent && _salePlanMonths == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please select a plan'),
                    backgroundColor: AppColors.error),
              );
              return;
            }
            _goToStep(3);
          },
          nextLabel: 'Next — Map',
        ),
      ],
    );
  }

  Widget _buildFreePlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.home_outlined,
                color: AppColors.textPrimary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Free Listing',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Standard visibility, no additional cost.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Auto-selected',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSalePlanCard(
      int months, String title, int price, String description) {
    final selected = _salePlanMonths == months;
    return GestureDetector(
      onTap: () => setState(() => _salePlanMonths = months),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                months == 6 ? Icons.diamond_outlined : Icons.star_outlined,
                color: selected ? Colors.white : AppColors.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('EGP $price',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                    color: selected ? AppColors.primary : AppColors.textHint),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: DOCUMENTS  (Gov ID + Ownership Proof + Supporting)
  // ---------------------------------------------------------------------------
  Widget _buildDocumentsStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // --- Government ID ---
        _buildLabel('National ID / Passport * (مطلوب — ملف واحد)'),
        const SizedBox(height: AppSpacing.sm),
        _buildSingleDocTile(
          file: _govIdDoc,
          onPick: () => _pickSingleDoc((f) => _govIdDoc = f),
          onDelete: () => setState(() => _govIdDoc = null),
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Ownership Proof ---
        _buildLabel(
            'Ownership Proof — Property Contract or Utility Bill * (Required — 1 file)'),
        const SizedBox(height: AppSpacing.sm),
        _buildSingleDocTile(
          file: _ownershipDoc,
          onPick: () => _pickSingleDoc((f) => _ownershipDoc = f),
          onDelete: () => setState(() => _ownershipDoc = null),
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Supporting Docs ---
        _buildLabel('Supporting Documentation (Optional — max 3)'),
        const SizedBox(height: AppSpacing.sm),
        _buildSupportingDocsGrid(),
        const SizedBox(height: AppSpacing.xl),

        // --- Privacy notice ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.navyBlue.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.navyBlue.withAlpha(30)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 20, color: AppColors.navyBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your documents are secure. They are encrypted, reviewed only by our verification team, and permanently deleted after approval. We never share them with renters or third parties.',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.navyBlue.withAlpha(200),
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        _buildNavButtons(
          onBack: () => _goToStep(3),
          onNext: () {
            if (_govIdDoc == null) {
              _showError('Please upload your National ID / Passport');
              return;
            }
            if (_ownershipDoc == null) {
              _showError('Please upload your Ownership Proof');
              return;
            }
            if (_isForRent) {
              setState(() => _isSubmitting = true);
              _submitProperty().then((data) {
                if (mounted) setState(() => _isSubmitting = false);
                if (data != null) _showPropertyAddedDialog();
              });
            } else {
              _goToStep(5);
            }
          },
          nextLabel: _isForRent ? 'Submit Property' : 'Next — Invoice',
          isLoading: _isForRent ? _isSubmitting : false,
        ),
      ],
    );
  }

  Widget _buildSingleDocTile(
      {required XFile? file,
      required VoidCallback onPick,
      required VoidCallback onDelete}) {
    if (file != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              width: 90,
              height: 90,
              child: kIsWeb
                  ? _PickedImageTile(file: file)
                  : Image.file(File(file.path), fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.error),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          border:
              Border.all(color: AppColors.primary.withAlpha(100), width: 1.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          color: AppColors.primary.withAlpha(10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_outlined,
                color: AppColors.primary, size: 28),
            SizedBox(height: 2),
            Text('Upload',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSingleDoc(void Function(XFile) onPicked) async {
    final files = await ImagePicker().pickMultiImage();
    if (files.isNotEmpty) {
      setState(() => onPicked(files.first));
    }
  }

  Widget _buildSupportingDocsGrid() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ..._supportingDocs.map((f) => _buildDocThumb(f, () {
              setState(() => _supportingDocs.remove(f));
            })),
        if (_supportingDocs.length < 3)
          GestureDetector(
            onTap: _pickSupportingDocs,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignInside),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.primary, size: 28),
                  SizedBox(height: 2),
                  Text('Add',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocThumb(XFile file, VoidCallback onDelete) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: SizedBox(
            width: 90,
            height: 90,
            child: kIsWeb
                ? _PickedImageTile(file: file)
                : Image.file(File(file.path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.error),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickSupportingDocs() async {
    final files = await ImagePicker().pickMultiImage();
    if (files.isNotEmpty) {
      setState(() {
        for (final f in files) {
          if (_supportingDocs.length < 3) _supportingDocs.add(f);
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 5: INVOICE & PAYMENT  (sale only)
  // ---------------------------------------------------------------------------
  Widget _buildInvoiceStep() {
    final planMonths = _salePlanMonths ?? 1;
    final planFee = planMonths == 1
        ? 120
        : planMonths == 3
            ? 360
            : 600;
    final previewImages = _propertyImages.take(2).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // --- Header ---
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Invoice & Summary',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Review your property and payment details',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Property Preview (first 2 images) ---
        if (previewImages.isNotEmpty) ...[
          const Text('Property Preview',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                  letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: previewImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 200,
                    child: kIsWeb
                        ? _PickedImageTile(file: previewImages[i])
                        : Image.file(File(previewImages[i].path),
                            fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // --- Invoice Breakdown ---
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Property Summary',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _summaryRow('Title', _titleCtl.text),
              _summaryRow('Type', 'For Sale'),
              _summaryRow('Price', 'EGP ${_priceCtl.text}'),
              _summaryRow('Size', '${_sizeCtl.text} m\u00B2'),
              _summaryRow('Images', '${_propertyImages.length} selected'),
              if (_govIdDoc != null)
                _summaryRow('National ID', 'Uploaded ✓',
                    valueColor: AppColors.success),
              if (_ownershipDoc != null)
                _summaryRow('Ownership Proof', 'Uploaded ✓',
                    valueColor: AppColors.success),
              const Divider(height: AppSpacing.lg),
              const Text('Cost Breakdown',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '$planMonths Month${planMonths > 1 ? 's' : ''} Sale Plan',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  Text('EGP $planFee',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
              const Divider(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  Text('EGP $planFee',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Proceed to Payment ---
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting
                ? null
                : () => _processSalePayment(),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.credit_card, color: Colors.white),
            label: Text(
              _isSubmitting
                  ? 'Processing...'
                  : 'الاستمرار للدفع  •  EGP $planFee',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: _isSubmitting ? null : () => _goToStep(4),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.borderLight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Go Back & Edit'),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13,
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: valueColor != null ? FontWeight.w600 : null),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------------------------
  String? _extractMsg(dynamic data) =>
      data is Map ? data['msg'] as String? : null;

  DioMediaType? _detectMime(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return DioMediaType('image', 'jpeg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47 &&
        bytes[4] == 0x0D && bytes[5] == 0x0A &&
        bytes[6] == 0x1A && bytes[7] == 0x0A) {
      return DioMediaType('image', 'png');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 &&
        bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 &&
        bytes[10] == 0x42 && bytes[11] == 0x50) {
      return DioMediaType('image', 'webp');
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 && bytes[1] == 0x50 &&
        bytes[2] == 0x44 && bytes[3] == 0x46) {
      return DioMediaType('application', 'pdf');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _submitProperty() async {
    if (_isSubmittingProperty) return null;
    _isSubmittingProperty = true;
    if (_lat == null || _lng == null) {
      _isSubmittingProperty = false;
      _showError(
          'Please go back to the Map step and confirm your property location');
      return null;
    }
    if (_resolvedAddress.isEmpty) {
      _isSubmittingProperty = false;
      _showError(
          'Verified address is missing. Please go back to the Map step.');
      return null;
    }
    if (_propertyImages.isEmpty) {
      _isSubmittingProperty = false;
      _showError('Please upload at least one property image');
      return null;
    }

    try {
      final dio = di.sl<ApiClient>().dio;
      final formData = FormData.fromMap({
        'propertyName': _titleCtl.text.trim(),
        'propertyDesc': _descCtl.text.trim(),
        'location': _resolvedAddress,
        'latitude': _lat!.toStringAsFixed(6),
        'longitude': _lng!.toStringAsFixed(6),
        'pricingUnit': _rentPeriod.value,
        'priceValue': _priceCtl.text.trim(),
        'size': _sizeCtl.text.trim(),
        'bedroomsNumber':
            _bedroomsCtl.text.trim().isEmpty ? '0' : _bedroomsCtl.text.trim(),
        'bedsNumber': _bedsCtl.text.trim().isEmpty ? '0' : _bedsCtl.text.trim(),
        'bathroomsNumber':
            _bathroomsCtl.text.trim().isEmpty ? '0' : _bathroomsCtl.text.trim(),
        'is_furnished': _isFurnished ? 'true' : 'false',
        'property_type': _isForRent ? 'for_rent' : 'for_sale',
        'sellingPlan':
            _isForRent || _salePlanMonths == null ? '' : '$_salePlanMonths',
      });

      for (final img in _propertyImages) {
        final bytes = await img.readAsBytes();
        final rawName = img.path.split(RegExp(r'[/\\]')).last;
        final mime = _detectMime(bytes);
        final ext = mime?.subtype.replaceAll('jpeg', 'jpg');
        formData.files.add(MapEntry(
          'images',
          MultipartFile.fromBytes(
            bytes,
            filename: ext != null && !rawName.contains('.')
                ? '$rawName.$ext'
                : rawName,
            contentType: mime,
          ),
        ));
      }
      for (final doc in _allDocFiles()) {
        final bytes = await doc.readAsBytes();
        final rawName = doc.path.split(RegExp(r'[/\\]')).last;
        final mime = _detectMime(bytes);
        final ext = mime?.subtype.replaceAll('jpeg', 'jpg');
        formData.files.add(MapEntry(
          'ownershipProof',
          MultipartFile.fromBytes(
            bytes,
            filename: ext != null && !rawName.contains('.')
                ? '$rawName.$ext'
                : rawName,
            contentType: mime,
          ),
        ));
      }

      final response = await dio.post('/property', data: formData);
      _isSubmittingProperty = false;
      if (!mounted) return null;

      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>?;
      } else {
        _showError(_extractMsg(response.data) ?? 'Failed to list property');
        return null;
      }
    } on DioException catch (e) {
      _isSubmittingProperty = false;
      _showError(_extractMsg(e.response?.data) ??
          'No internet connection. Please try again.');
      return null;
    } catch (e) {
      _isSubmittingProperty = false;
      _showError('Error: ${e.runtimeType}: $e');
      return null;
    }
  }

  void _showPropertyAddedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'تم رفع العقار بنجاح',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Your property has been submitted for admin review.\nYou will be notified once it is approved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Back to My Properties',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processSalePayment() async {
    if (_isSubmitting) return;
    final guardOk = await BiometricAuthGuard.guard(
      context,
      reason: 'Authenticate to confirm your payment',
    );
    if (!guardOk) return;
    if (!mounted) return;
    final planMonths = _salePlanMonths ?? 1;
    setState(() => _isSubmitting = true);
    try {
      final responseData = await _submitProperty();
      if (!mounted) return;
      if (responseData == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      final propertyId = _parseInt(responseData['property_id'], fallback: -1);
      if (propertyId <= 0) {
        setState(() => _isSubmitting = false);
        _showError('Could not determine property ID');
        return;
      }

      final subscriptionResult = await di.sl<CreateSubscriptionUseCase>()(
        CreateSubscriptionParams(
          propertyId: propertyId,
          planMonths: planMonths,
        ),
      );
      if (!mounted) return;

      final subscriptionId = subscriptionResult.fold(
        (failure) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
          return null;
        },
        (sub) => sub.subscriptionId,
      );

      if (subscriptionId == null || subscriptionId.isEmpty) return;

      final linkResult = await di.sl<GetPaymentLinkUseCase>()(
        GetPaymentLinkParams(
          subscriptionId: subscriptionId,
          redirect: 'https://aqar.app/payment-callback',
        ),
      );
      if (!mounted) return;

      linkResult.fold(
        (failure) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
        (link) async {
          final ok = await KashierWebViewPage.open(context, url: link.url);
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          if (ok == true && mounted) {
            _showPropertyAddedDialog();
          } else if (ok != true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Payment cancelled or failed'),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: _processSalePayment,
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }



  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  List<XFile> _allDocFiles() {
    final list = <XFile>[];
    if (_govIdDoc != null) list.add(_govIdDoc!);
    if (_ownershipDoc != null) list.add(_ownershipDoc!);
    list.addAll(_supportingDocs);
    return list;
  }

  String _nonNull(dynamic v) => v?.toString().trim() ?? '';

  int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _goToStep(int step) {
    _pageCtrl.animateToPage(step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
    );
  }

  Widget _buildTextField(TextEditingController ctl, String hint,
      {String? Function(String?)? validator, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctl,
      validator: validator,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint: hint),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _rentPeriodRadio(RentPeriod period) {
    return GestureDetector(
      onTap: () => setState(() => _rentPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: _rentPeriod == period
              ? AppColors.primary.withAlpha(15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: _rentPeriod == period
                ? AppColors.primary
                : AppColors.borderLight,
            width: _rentPeriod == period ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _rentPeriod == period
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18,
              color: _rentPeriod == period
                  ? AppColors.primary
                  : AppColors.textHint,
            ),
            const SizedBox(width: 8),
            Text(
              period.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _rentPeriod == period
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldGroup(String label, TextEditingController ctl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: ctl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButtons(
      {VoidCallback? onBack,
      VoidCallback? onNext,
      String? nextLabel,
      bool isLoading = false}) {
    return Row(
      children: [
        if (onBack != null)
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.borderLight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Back'),
            ),
          ),
        if (onBack != null && onNext != null)
          const SizedBox(width: AppSpacing.md),
        if (onNext != null)
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLoading ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                minimumSize: const Size(0, 48),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(nextLabel ?? 'Next'),
            ),
          ),
      ],
    );
  }
}

class _PickedImageTile extends StatefulWidget {
  final XFile file;
  const _PickedImageTile({required this.file});

  @override
  State<_PickedImageTile> createState() => _PickedImageTileState();
}

class _PickedImageTileState extends State<_PickedImageTile> {
  Uint8List? _bytes;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await widget.file.readAsBytes();
      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: AppColors.surfaceLight,
        child:
            const Icon(Icons.broken_image_outlined, color: AppColors.textHint),
      );
    }
    if (_bytes == null) {
      return const Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Image.memory(_bytes!, fit: BoxFit.cover),
    );
  }
}

class _SearchResult {
  final String displayName;
  final double lat;
  final double lon;
  const _SearchResult(
      {required this.displayName, required this.lat, required this.lon});
}

class _FullScreenImagePreview extends StatefulWidget {
  final List<XFile> images;
  final int initialIndex;
  const _FullScreenImagePreview({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImagePreview> createState() =>
      _FullScreenImagePreviewState();
}

class _FullScreenImagePreviewState extends State<_FullScreenImagePreview> {
  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} of ${widget.images.length}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: PageView.builder(
          controller: _pageCtrl,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (_, i) {
            final file = widget.images[i];
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: ClipRRect(
                  child: kIsWeb
                      ? _PickedImageTile(file: file)
                      : Image.file(File(file.path),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_outlined,
                                      color: Colors.white54, size: 64),
                                  SizedBox(height: 8),
                                  Text('Could not load image',
                                      style: TextStyle(color: Colors.white54)),
                                ],
                              )),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


