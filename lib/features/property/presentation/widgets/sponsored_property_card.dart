import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/property_entity.dart';
import 'property_image.dart';

class SponsoredPropertyCard extends StatelessWidget {
  final PropertyEntity property;
  final VoidCallback onTap;
  final VoidCallback onFavTap;
  final bool isFavorite;

  const SponsoredPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    required this.onFavTap,
    this.isFavorite = false,
  });

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFE5C45A);

  @override
  Widget build(BuildContext context) {
    final bool isSponsored = property.isSponsored;

    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = constraints.maxWidth;
        if (cardWidth.isInfinite || cardWidth == 0) {
          final screenWidth = MediaQuery.of(context).size.width;
          cardWidth = screenWidth * 0.42;
          if (cardWidth > 260) cardWidth = 260;
          if (cardWidth < 180) cardWidth = 180;
        }

        final double imageHeight = cardWidth * 0.6;
        final double titleFontSize = cardWidth < 180 ? 12.0 : 14.0;
        final double priceFontSize = cardWidth < 180 ? 12.0 : 14.0;
        final double locationFontSize = cardWidth < 180 ? 10.0 : 11.0;
        final double infoFontSize = cardWidth < 180 ? 9.0 : 10.0;
        final double iconSize = cardWidth < 180 ? 12.0 : 14.0;

        return GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: cardWidth,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSponsored ? _gold.withValues(alpha: 0.5) : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSponsored
                        ? _gold.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: isSponsored ? 12 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: property.images.isNotEmpty
                            ? PropertyImage(
                                imageUrl: property.images.first,
                                height: imageHeight,
                                width: double.infinity,
                              )
                            : _buildPlaceholder(imageHeight),
                      ),
                      if (isSponsored)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_gold, _goldLight],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.auto_awesome,
                                    size: 10, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'SPONSORED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onFavTap,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                                color: isFavorite
                                    ? _gold
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                property.propertyName,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '\$${property.priceValue.toStringAsFixed(0)}${property.pricingUnitSuffix}',
                                style: TextStyle(
                                  fontSize: priceFontSize,
                                  fontWeight: FontWeight.w800,
                                  color: isSponsored ? _gold : AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: iconSize, color: _gold),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                property.location,
                                style: TextStyle(
                                  fontSize: locationFontSize,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _infoItem(
                                Icons.bed_outlined,
                                '${property.bedroomsNo}',
                                iconSize,
                                infoFontSize),
                            _infoItem(
                                Icons.bathtub_outlined,
                                '${property.bathroomsNo}',
                                iconSize,
                                infoFontSize),
                            _infoItem(Icons.square_foot_outlined, property.size,
                                iconSize, infoFontSize),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: property.status.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              property.status.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: property.status.color,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoItem(
      IconData icon, String label, double iconSize, double fontSize) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: _gold),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              label,
              style:
                  TextStyle(fontSize: fontSize, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.surfaceLight,
      child:
          const Icon(Icons.home_outlined, size: 36, color: AppColors.textHint),
    );
  }

}
