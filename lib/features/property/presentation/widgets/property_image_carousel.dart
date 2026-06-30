import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'property_image.dart';

class PropertyImageCarousel extends StatelessWidget {
  final List<String> images;
  final VoidCallback onTap;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final PageController pageController;

  const PropertyImageCarousel({
    super.key,
    required this.images,
    required this.onTap,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    final clampedHeight = (MediaQuery.of(context).size.height * 0.38).clamp(260, 420).toDouble();
    return SliverAppBar(
      expandedHeight: clampedHeight,
      automaticallyImplyLeading: false,
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
      child: Center(
        child: Icon(Icons.home_outlined, size: 76, color: AppColors.textHint),
      ),
    );
  }

  Widget _buildCarousel(double height) {
    return Stack(
      children: [
        PageView.builder(
          controller: pageController,
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
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
            child: Column(
              children: [
                _buildProgressBar(),
                const SizedBox(height: 6),
                Text(
                  '${currentIndex + 1} / ${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(images.length, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
          ),
        );
      }),
    );
  }
}
