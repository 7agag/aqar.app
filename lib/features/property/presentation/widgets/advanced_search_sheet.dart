import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aqar_button.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';
import '../../domain/entities/search_filter.dart';

class AdvancedSearchSheet extends StatefulWidget {
  final String? initialLocation;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final int? initialBedrooms;
  final int? initialBathrooms;
  final String? initialRentalDuration;
  final double? initialMinSize;
  final double? initialMaxSize;
  final List<PropertyEntity> allProperties;
  final bool isBuy;
  final void Function(SearchFilter filter) onApply;

  const AdvancedSearchSheet({
    super.key,
    this.initialLocation,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialBedrooms,
    this.initialBathrooms,
    this.initialRentalDuration,
    this.initialMinSize,
    this.initialMaxSize,
    required this.allProperties,
    required this.isBuy,
    required this.onApply,
  });

  @override
  State<AdvancedSearchSheet> createState() => _AdvancedSearchSheetState();
}

class _AdvancedSearchSheetState extends State<AdvancedSearchSheet> {
  late bool _isBuy;
  final _locationController = TextEditingController();
  final _minSizeController = TextEditingController();
  final _maxSizeController = TextEditingController();
  double _minPrice = 0;
  double _maxPrice = 5000000;
  int _bedrooms = 0;
  int _bathrooms = 0;
  String _rentalDuration = 'all';
  double _minSize = 0;
  double _maxSize = 10000;
  late final double _priceMax;
  late final double _sizeMax;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isBuy = widget.isBuy;

    _priceMax = widget.allProperties.isEmpty
        ? 5000000
        : widget.allProperties
            .map((p) => p.priceValue)
            .reduce((a, b) => a > b ? a : b);
    _sizeMax = widget.allProperties.isEmpty
        ? 10000
        : widget.allProperties
            .map((p) => double.tryParse(p.size) ?? 0)
            .reduce((a, b) => a > b ? a : b);

    _locationController.text = widget.initialLocation ?? '';
    _minSize = widget.initialMinSize ?? 0;
    _maxSize = widget.initialMaxSize ?? _sizeMax;
    _minSizeController.text = _minSize.toInt().toString();
    _maxSizeController.text = _maxSize.toInt().toString();
    _minPrice = widget.initialMinPrice ?? 0;
    _maxPrice = widget.initialMaxPrice ?? _priceMax;
    _bedrooms = widget.initialBedrooms ?? 0;
    _bathrooms = widget.initialBathrooms ?? 0;
    _rentalDuration = widget.initialRentalDuration ?? 'all';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minSizeController.dispose();
    _maxSizeController.dispose();
    super.dispose();
  }

  int get _totalFilteredCount {
    List<PropertyEntity> filtered = List.from(widget.allProperties);

    final targetType = _isBuy ? ListingType.forSale : ListingType.forRent;
    filtered = filtered.where((p) => p.listingType == targetType).toList();

    if (_locationController.text.isNotEmpty) {
      filtered = filtered
          .where((p) => p.location
              .toLowerCase()
              .contains(_locationController.text.toLowerCase()))
          .toList();
    }

    if (_rentalDuration != 'all') {
      filtered = filtered
          .where((p) =>
              p.listingType == ListingType.forRent &&
              p.pricingUnit.value == _rentalDuration)
          .toList();
    }

    filtered = filtered
        .where((p) => p.priceValue >= _minPrice && p.priceValue <= _maxPrice)
        .toList();

    if (_bedrooms > 0) {
      filtered = filtered.where((p) => p.bedroomsNo >= _bedrooms).toList();
    }

    if (_bathrooms > 0) {
      filtered = filtered.where((p) => p.bathroomsNo >= _bathrooms).toList();
    }

    filtered = filtered.where((p) {
      final size = double.tryParse(p.size) ?? 0;
      return size >= _minSize && size <= _maxSize;
    }).toList();

    return filtered.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _resetFilters,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildBuyRentToggle(),
            const SizedBox(height: 20),
            _buildLabel('Location'),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'e.g. Manhattan, NY',
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: AppColors.textHint, size: 20),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!_isBuy) ...[
              _buildLabel('Rental Duration'),
              const SizedBox(height: 10),
              _buildRentalDurationChips(),
              const SizedBox(height: 20),
            ],
            _buildLabel(
                'Price Range  (\$${_minPrice.toInt()} - \$${_maxPrice.toInt()})'),
            RangeSlider(
              values: RangeValues(_minPrice, _maxPrice),
              min: 0,
              max: _priceMax,
              divisions: (_priceMax / 50000).round().clamp(1, 200),
              activeColor: AppColors.primary,
              inactiveColor: AppColors.borderLight,
              onChanged: (v) => setState(() {
                _minPrice = v.start;
                _maxPrice = v.end;
              }),
            ),
            const SizedBox(height: 12),
            _buildLabel('Bedrooms'),
            const SizedBox(height: 10),
            _buildBedroomsChips(),
            const SizedBox(height: 20),
            _buildLabel('Bathrooms'),
            const SizedBox(height: 10),
            _buildBathroomsChips(),
            const SizedBox(height: 20),
            _buildLabel('Size (sqft)'),
            const SizedBox(height: 8),
            _buildSizeRange(),
            const SizedBox(height: 28),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            AqarButton(
              text: 'Show Results ($_totalFilteredCount)',
              onPressed: _applyFilters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyRentToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
              child: _toggleTab(
                  'Buy', _isBuy, () => setState(() => _isBuy = true))),
          Expanded(
              child: _toggleTab(
                  'Rent', !_isBuy, () => setState(() => _isBuy = false))),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6)
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRentalDurationChips() {
    final List<Map<String, dynamic>> durations = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Daily', 'value': 'DAY'},
      {'label': 'Monthly', 'value': 'MONTH'},
      {'label': 'Yearly', 'value': 'YEAR'},
    ];

    return Wrap(
      spacing: 8,
      children: durations.map((item) {
        final isSelected = _rentalDuration == item['value'];
        return _buildChip(
          item['label'] as String,
          isSelected,
          () {
            setState(() => _rentalDuration = item['value'] as String);
          },
        );
      }).toList(),
    );
  }

  Widget _buildBedroomsChips() {
    final List<Map<String, dynamic>> options = [
      {'label': 'Any', 'value': 0},
      {'label': '1', 'value': 1},
      {'label': '2', 'value': 2},
      {'label': '3', 'value': 3},
      {'label': '4+', 'value': 4},
    ];

    return Wrap(
      spacing: 8,
      children: options.map((item) {
        final isSelected = _bedrooms == item['value'];
        return _buildChip(
          item['label'] as String,
          isSelected,
          () {
            setState(() => _bedrooms = item['value'] as int);
          },
        );
      }).toList(),
    );
  }

  Widget _buildBathroomsChips() {
    final List<Map<String, dynamic>> options = [
      {'label': 'Any', 'value': 0},
      {'label': '1', 'value': 1},
      {'label': '2', 'value': 2},
      {'label': '3', 'value': 3},
      {'label': '3+', 'value': 4},
    ];

    return Wrap(
      spacing: 8,
      children: options.map((item) {
        final isSelected = _bathrooms == item['value'];
        return _buildChip(
          item['label'] as String,
          isSelected,
          () {
            setState(() => _bathrooms = item['value'] as int);
          },
        );
      }).toList(),
    );
  }

  Widget _buildChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSizeRange() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Min Size',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minSizeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _minSize = double.tryParse(value) ?? 0;
                            _error = null;
                          });
                        },
                      ),
                    ),
                    const Text(
                      'sqft',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Max Size',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxSizeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _maxSize = double.tryParse(value) ?? _sizeMax;
                            _error = null;
                          });
                        },
                      ),
                    ),
                    const Text(
                      'sqft',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _isBuy = widget.isBuy;
      _locationController.clear();
      _minPrice = 0;
      _maxPrice = _priceMax;
      _bedrooms = 0;
      _bathrooms = 0;
      _rentalDuration = 'all';
      _minSize = 0;
      _maxSize = _sizeMax;
      _minSizeController.text = '0';
      _maxSizeController.text = _sizeMax.toInt().toString();
      _error = null;
    });
  }

  void _applyFilters() {
    if (_minPrice > _maxPrice) {
      setState(() => _error = 'Min price cannot exceed max price');
      return;
    }
    if (_minSize > _maxSize) {
      setState(() => _error = 'Min size cannot exceed max size');
      return;
    }

    widget.onApply(
      SearchFilter(
        isBuy: _isBuy,
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < _priceMax ? _maxPrice : null,
        bedrooms: _bedrooms > 0 ? _bedrooms : null,
        bathrooms: _bathrooms > 0 ? _bathrooms : null,
        rentalDuration: _rentalDuration != 'all' ? _rentalDuration : null,
        minSize: _minSize > 0 ? _minSize : null,
        maxSize: _maxSize < _sizeMax ? _maxSize : null,
      ),
    );
    Navigator.pop(context);
  }
}
