// lib/features/property/presentation/widgets/nearby_property_card.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/extensions/num_formatting.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/property_entity.dart';
import 'property_image.dart';

class NearbyPropertyCard extends StatelessWidget {
  final PropertyEntity property;
  final VoidCallback onTap;
  final VoidCallback onFavTap;
  final bool isFavorite;
  final double? userLat;
  final double? userLng;

  const NearbyPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    required this.onFavTap,
    this.isFavorite = false,
    this.userLat,
    this.userLng,
  });

  String _distanceText() {
    final lat = property.latitude;
    final lng = property.longitude;
    if (lat == null || lng == null || userLat == null || userLng == null) {
      return '';
    }
    final dist = _haversine(userLat!, userLng!, lat, lng);
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: property.images.isNotEmpty
                  ? PropertyImage(
                      imageUrl: property.images.first,
                      width: 100,
                      height: 100,
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    property.propertyName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  const SizedBox(height: 4),
                  if (property.latitude != null && property.longitude != null && userLat != null && userLng != null)
                    Row(
                      children: [
                        Icon(
                          Icons.near_me_outlined,
                          size: 14,
                          color: const Color(0xFFD4AF37),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _distanceText(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${property.priceValue.formatWithCommas()}${property.pricingUnitSuffix}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bed_outlined,
                            size: 14,
                            color: const Color(0xFFD4AF37),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${property.bedroomsNo}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.bathtub_outlined,
                            size: 14,
                            color: const Color(0xFFD4AF37),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${property.bathroomsNo}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Favorite button
            GestureDetector(
              onTap: onFavTap,
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? const Color(0xFFD4AF37) : AppColors.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.surfaceLight,
      child: const Icon(
        Icons.home_outlined,
        size: 28,
        color: AppColors.textHint,
      ),
    );
  }

}