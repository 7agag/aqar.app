import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color badgeColor;
  final double iconSize;
  final VoidCallback? onPressed;

  const BadgeIcon({
    super.key,
    required this.icon,
    this.count = 0,
    this.badgeColor = AppColors.error,
    this.iconSize = 24,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(icon, color: AppColors.textPrimary, size: iconSize),
            ),
          ),
          if (count > 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
