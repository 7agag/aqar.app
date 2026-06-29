import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';

enum MapFilter { all, forRent, forSale }

class MapFilterBar extends StatelessWidget {
  final MapFilter selected;
  final ValueChanged<MapFilter> onChanged;

  const MapFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip(MapFilter.all, 'All'),
        const SizedBox(width: 8),
        _chip(MapFilter.forRent, 'For Rent'),
        const SizedBox(width: 8),
        _chip(MapFilter.forSale, 'For Sale'),
      ],
    );
  }

  Widget _chip(MapFilter filter, String label) {
    final isActive = selected == filter;
    return GestureDetector(
      onTap: () => onChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.navyBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.navyBlue : Colors.white.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
