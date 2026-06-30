import 'package:flutter/material.dart';
import 'package:aqar/core/extensions/num_formatting.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/features/property/presentation/widgets/property_image.dart';

class PropertyInfoWindow extends StatelessWidget {
  final PropertyEntity property;
  final VoidCallback onViewDetails;
  final VoidCallback onClose;

  const PropertyInfoWindow({
    super.key,
    required this.property,
    required this.onViewDetails,
    required this.onClose,
  });

  String get _formattedPrice {
    final suffix = property.listingType.name == 'forRent' ? '/mo' : '';
    return '${property.priceValue.formatWithCommas()} EGP$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final status = property.status;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 260,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                        child: SizedBox(
                          height: 130,
                          width: double.infinity,
                          child: property.images.isNotEmpty
                              ? PropertyImage(
                                  imageUrl: property.images.first,
                                  width: double.infinity,
                                  height: 130,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: AppColors.surfaceLight,
                                  child: Center(
                                    child: Icon(Icons.home_outlined,
                                        size: 40, color: AppColors.textHint),
                                  ),
                                ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.propertyName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formattedPrice,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyBlue,
                              ),
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: status.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status.label,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: status.color,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.location_on_rounded,
                                    size: 12,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.6)),
                                SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    property.location,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.7)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 34,
                              child: ElevatedButton(
                                onPressed: onViewDetails,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navyBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 0),
                                ),
                                child: const Text(
                                  'View Full Details',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ClipPath(
          clipper: _ArrowClipper(),
          child: Container(
            width: 16,
            height: 10,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
