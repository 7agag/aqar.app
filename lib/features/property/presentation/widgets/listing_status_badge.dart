import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';

class ListingStatusBadge extends StatelessWidget {
  final PropertyEntity property;

  const ListingStatusBadge({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    late String text;
    late Color color;

    if (property.listingStatus == ListingStatus.sold) {
      if (property.listingType == ListingType.forRent) {
        text = AppStrings.rented;
        color = const Color(0xFFE67E22);
      } else {
        text = AppStrings.sold;
        color = const Color(0xFFE24B4A);
      }
    } else if (property.listingType == ListingType.forSale) {
      text = AppStrings.forSale;
      color = const Color(0xFF1A2744);
    } else {
      text = AppStrings.forRent;
      color = const Color(0xFF1D9E75);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
