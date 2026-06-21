import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'property_image.dart';

class PropertyImageCarousel extends StatelessWidget {
  final List<String> images;
  final VoidCallback onTap;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const PropertyImageCarousel({
    super.key,
    required this.images,
    required this.onTap,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clampedHeight = (MediaQuery.of(context).size.height * 0.35).clamp(220, 400).toDouble();
    return SliverAppBar(
      expandedHeight: clampedHeight,
      pinned: false,
      floating: false,
      flexibleSpace: FlexibleSpaceBar(
        background: images.isEmpty ? _buildPlaceholder() : _buildCarousel(clampedHeight),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(Icons.home_outlined, size: 76, color: AppColors.textHint),
      ),
    );
  }

  Widget _buildCarousel(double height) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: onIndexChanged,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: onTap,
              child: PropertyImage(
                imageUrl: images[index],
                height: height,
              ),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: _buildDots(),
        ),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(images.length, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentIndex
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.5),
          ),
        );
      }),
    );
  }
}
