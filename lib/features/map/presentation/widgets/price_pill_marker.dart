import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/property/domain/entities/property_enums.dart';

class PricePillMarker extends StatelessWidget {
  final int priceValue;
  final ListingType type;
  final bool isSelected;
  final VoidCallback onTap;

  const PricePillMarker({
    super.key,
    required this.priceValue,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  String get _formattedPrice {
    if (priceValue >= 1000000) {
      final m = priceValue / 1000000;
      return '${m.toStringAsFixed(m == m.truncateToDouble() ? 0 : 1)}M';
    }
    if (priceValue >= 1000) {
      final k = priceValue / 1000;
      return '${k.toStringAsFixed(k == k.truncateToDouble() ? 0 : 1)}K';
    }
    return priceValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isRent = type == ListingType.forRent;
    final color = isRent ? AppColors.success : AppColors.navyBlue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: isSelected ? 2 : 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isSelected ? 0.3 : 0.15),
                blurRadius: isSelected ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _formattedPrice,
                style: TextStyle(
                  fontSize: isSelected ? 13 : 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (isRent)
                Text(
                  '/mo',
                  style: TextStyle(
                    fontSize: isSelected ? 10 : 9,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
