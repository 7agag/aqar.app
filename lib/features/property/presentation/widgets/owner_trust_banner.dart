import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../domain/entities/property_entity.dart';

class OwnerTrustBanner extends StatelessWidget {
  final PropertyEntity property;
  const OwnerTrustBanner({super.key, required this.property});

  String get _initials {
    final f = (property.ownerFirstName ?? 'P')[0].toUpperCase();
    final s = (property.ownerSecondName ?? 'O')[0].toUpperCase();
    return '$f$s';
  }

  String get _fullName {
    final f = property.ownerFirstName ?? 'Property';
    final s = property.ownerSecondName ?? 'Owner';
    return '$f $s';
  }

  double get _rate => property.rate ?? 4.2;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceLight,
            child: Text(
              _initials,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFA000)),
                    SizedBox(width: 4),
                    Text(
                      _rate.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.navyBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.navyBlue.withValues(alpha: 0.15)),
            ),
            child: Text(
              AppStrings.isArabic ? 'المالك' : 'Owner',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.navyBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
