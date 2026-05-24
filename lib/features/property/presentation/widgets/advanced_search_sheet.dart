import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aqar_button.dart';

class AdvancedSearchSheet extends StatefulWidget {
  final String? initialLocation;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final int? initialBedrooms;
  final int? initialBathrooms;
  final String? initialPropertyType;
  final Function({
    String? location,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
    String? propertyType,
  }) onApply;

  const AdvancedSearchSheet({
    super.key,
    this.initialLocation,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialBedrooms,
    this.initialBathrooms,
    this.initialPropertyType,
    required this.onApply,
  });

  @override
  State<AdvancedSearchSheet> createState() => _AdvancedSearchSheetState();
}

class _AdvancedSearchSheetState extends State<AdvancedSearchSheet> {
  final _locationController = TextEditingController();
  double _minPrice = 0;
  double _maxPrice = 5000000;
  int _bedrooms = 0;
  int _bathrooms = 0;
  String _propertyType = 'all';

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.initialLocation ?? '';
    _minPrice = widget.initialMinPrice ?? 0;
    _maxPrice = widget.initialMaxPrice ?? 5000000;
    _bedrooms = widget.initialBedrooms ?? 0;
    _bathrooms = widget.initialBathrooms ?? 0;
    _propertyType = widget.initialPropertyType ?? 'all';
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            // Handle
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

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advanced Search',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _locationController.clear();
                      _minPrice = 0;
                      _maxPrice = 5000000;
                      _bedrooms = 0;
                      _bathrooms = 0;
                      _propertyType = 'all';
                    });
                  },
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

            const SizedBox(height: 24),

            // Location
            _buildLabel('Location'),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
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

            // Price Range
            _buildLabel(
                'Price Range  (\$${_minPrice.toInt()} - \$${_maxPrice.toInt()})'),
            RangeSlider(
              values: RangeValues(_minPrice, _maxPrice),
              min: 0,
              max: 5000000,
              divisions: 100,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.borderLight,
              onChanged: (v) => setState(() {
                _minPrice = v.start;
                _maxPrice = v.end;
              }),
            ),

            const SizedBox(height: 12),

            // Property Type
            _buildLabel('Property Type'),
            const SizedBox(height: 10),
            Row(
              children: [
                _typeChip('All', 'all'),
                const SizedBox(width: 8),
                _typeChip('For Rent', 'for_rent'),
                const SizedBox(width: 8),
                _typeChip('For Sale', 'for_sale'),
              ],
            ),

            const SizedBox(height: 20),

            // Bedrooms
            _buildLabel('Bedrooms'),
            const SizedBox(height: 10),
            _buildCounter(
              value: _bedrooms,
              onDecrement: () {
                if (_bedrooms > 0) setState(() => _bedrooms--);
              },
              onIncrement: () => setState(() => _bedrooms++),
            ),

            const SizedBox(height: 20),

            // Bathrooms
            _buildLabel('Bathrooms'),
            const SizedBox(height: 10),
            _buildCounter(
              value: _bathrooms,
              onDecrement: () {
                if (_bathrooms > 0) setState(() => _bathrooms--);
              },
              onIncrement: () => setState(() => _bathrooms++),
            ),

            const SizedBox(height: 28),

            // Apply Button
            AqarButton(
              text: 'Apply Filters',
              onPressed: () {
                widget.onApply(
                  location: _locationController.text.isNotEmpty
                      ? _locationController.text
                      : null,
                  minPrice: _minPrice > 0 ? _minPrice : null,
                  maxPrice: _maxPrice < 5000000 ? _maxPrice : null,
                  bedrooms: _bedrooms > 0 ? _bedrooms : null,
                  bathrooms: _bathrooms > 0 ? _bathrooms : null,
                  propertyType: _propertyType != 'all' ? _propertyType : null,
                );
                Navigator.pop(context);
              },
            ),
          ],
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

  Widget _typeChip(String label, String value) {
    final isSelected = _propertyType == value;
    return GestureDetector(
      onTap: () => setState(() => _propertyType = value),
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

  Widget _buildCounter({
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        _counterBtn(Icons.remove, onDecrement),
        const SizedBox(width: 16),
        Text(
          value == 0 ? 'Any' : '$value+',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 16),
        _counterBtn(Icons.add, onIncrement),
      ],
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}
