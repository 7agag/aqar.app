import 'package:flutter/material.dart';

class PropertyImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;

  const PropertyImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  static const _fallbackUrls = [
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=600',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
  ];

  @override
  Widget build(BuildContext context) {
    return _NetworkImageWithFallback(
      url: imageUrl,
      fallback: _fallbackUrls[imageUrl.hashCode.abs() % _fallbackUrls.length],
      height: height,
      width: width,
      fit: fit,
    );
  }
}

class _NetworkImageWithFallback extends StatelessWidget {
  final String url;
  final String fallback;
  final double? height;
  final double? width;
  final BoxFit fit;

  const _NetworkImageWithFallback({
    required this.url,
    required this.fallback,
    this.height,
    this.width,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _loadingPlaceholder();
      },
      errorBuilder: (_, __, ___) => Image.network(
        fallback,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadingPlaceholder();
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: const Color(0xFFF5F5F5),
      child: const Icon(Icons.home_outlined, size: 36, color: Color(0xFFBDBDBD)),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: const Color(0xFFF5F5F5),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
