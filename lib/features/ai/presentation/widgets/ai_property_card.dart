import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/extensions/num_formatting.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../property/presentation/pages/property_detail_page.dart';
import '../../../property/presentation/widgets/property_image.dart';

class AiPropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;

  const AiPropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final propertyId = _parsePropertyId(property);
    final imageUrl = _firstImageUrl(property);

    final card = Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? PropertyImage(
                    imageUrl: imageUrl,
                    width: 64,
                    height: 64,
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _title(property),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (_location(property).isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _location(property),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 5),
                Text(
                  _priceText(property),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary.withValues(alpha: 0.95),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (propertyId > 0) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ],
        ],
      ),
    );

    if (propertyId <= 0) {
      return card;
    }

    return InkWell(
      onTap: () => _openProperty(context, propertyId),
      borderRadius: BorderRadius.circular(10),
      child: card,
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.white.withValues(alpha: 0.14),
      child: Icon(
        Icons.home_outlined,
        size: 28,
        color: Colors.white.withValues(alpha: 0.65),
      ),
    );
  }

  String _title(Map<String, dynamic> property) {
    final propertyName = property['property_name']?.toString().trim();
    if (propertyName != null && propertyName.isNotEmpty) return propertyName;
    final title = property['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;
    return 'Listing';
  }

  String _location(Map<String, dynamic> property) {
    final location = property['location']?.toString().trim();
    if (location != null && location.isNotEmpty) return location;
    final address = property['address']?.toString().trim();
    if (address != null && address.isNotEmpty) return address;
    return '';
  }

  String _priceText(Map<String, dynamic> property) {
    final raw = property['price_value'] ?? property['price'];
    final value = _parseDouble(raw);
    if (value == null || value <= 0) return 'Price N/A';
    return '${value.formatWithCommas()} EGP';
  }

  String? _firstImageUrl(Map<String, dynamic> property) {
    final directImage =
        property['image'] ?? property['image_url'] ?? property['property_img'];
    final raw = _firstRawImage(property['images']) ?? directImage?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return _normalizeImageUrl(raw.trim());
  }

  String? _firstRawImage(dynamic rawImages) {
    if (rawImages is List && rawImages.isNotEmpty) {
      return rawImages.first?.toString();
    }
    if (rawImages is String && rawImages.trim().isNotEmpty) {
      final trimmed = rawImages.trim();
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first?.toString();
        }
      } on FormatException {
        return trimmed;
      }
      return trimmed;
    }
    return null;
  }

  String _normalizeImageUrl(String path) {
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) return '${AppConfig.imageBaseUrl}$path';
    if (path.startsWith('uploads/')) return '${AppConfig.imageBaseUrl}/$path';
    return '${AppConfig.imageBaseUrl}/uploads/$path';
  }

  int _parsePropertyId(Map<String, dynamic> property) {
    final raw =
        property['property_id'] ?? property['propertyId'] ?? property['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  double? _parseDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.replaceAll(',', '').trim());
    return null;
  }

  void _openProperty(BuildContext context, int propertyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailPage(propertyId: propertyId),
      ),
    );
  }
}
