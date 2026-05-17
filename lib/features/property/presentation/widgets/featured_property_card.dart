import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/property_entity.dart';

class FeaturedPropertyCard extends StatelessWidget {
  final PropertyEntity property;
  final VoidCallback onTap;
  final VoidCallback onFavTap;

  const FeaturedPropertyCard({
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
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: property.images.isNotEmpty
                      ? Image.network(
                          property.images.first,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),

                // FEATURED badge
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Fav button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onFavTap,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.propertyName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${property.priceValue.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Location
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

                  // Beds, Baths, Size
                  Row(
                    children: [
                      _infoItem(
                          Icons.bed_outlined, '${property.bedroomsNo} Beds'),
                      const SizedBox(width: 10),
                      _infoItem(Icons.bathtub_outlined,
                          '${property.bathroomsNo} Baths'),
                      const SizedBox(width: 10),
                      _infoItem(
                          Icons.square_foot_outlined, '${property.size} m'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      color: AppColors.surfaceLight,
      child: const Icon(Icons.home_outlined,
          size: 40, color: AppColors.textHint),
    );
  }
}