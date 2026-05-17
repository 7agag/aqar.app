import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/property_entity.dart';

class NearbyPropertyCard extends StatelessWidget {
  final PropertyEntity property;
  final VoidCallback onTap;
  final VoidCallback onFavTap;

  const NearbyPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    required this.onFavTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: property.images.isNotEmpty
                  ? Image.network(
                      property.images.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.location,
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${property.priceValue.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.bed_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${property.bedroomsNo}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.bathtub_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${property.bathroomsNo}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Fav
            GestureDetector(
              onTap: onFavTap,
              child: const Icon(
                Icons.favorite_border,
                color: AppColors.textSecondary,
                size: 20,
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
      child: const Icon(Icons.home_outlined,
          size: 28, color: AppColors.textHint),
    );
  }
}