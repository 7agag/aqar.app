import 'dart:convert';

import 'package:aqar/core/config/app_config.dart';

import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';

class PropertyModel extends PropertyEntity {
  const PropertyModel({
    required super.propertyId,
    required super.ownerId,
    required super.propertyName,
    required super.propertyDesc,
    required super.location,
    super.latitude,
    super.longitude,
    required super.pricingUnit,
    required super.priceValue,
    required super.pricePerDay,
    required super.size,
    required super.bedroomsNo,
    required super.bedsNo,
    required super.bathroomsNo,
    required super.images,
    super.ownershipProofs,
    required super.isVerified,
    required super.isAvailable,
    required super.isFurnished,
    super.isSponsored,
    required super.listingType,
    super.rate,
    super.listingStatus,
    super.ownerFirstName,
    super.ownerSecondName,
    super.ownerEmail,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value.trim());
      return null;
    }

    List<String> parseList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((e) => _getFullImageUrl(e.toString())).toList();
      }
      if (raw is String && raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            return decoded.map((e) => _getFullImageUrl(e.toString())).toList();
          }
        } on FormatException {
          return [_getFullImageUrl(raw)];
        }
      }
      return [];
    }

    return PropertyModel(
      propertyId: parseInt(json['property_id']),
      ownerId: json['owner_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      propertyDesc: json['property_desc']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      latitude: parseNullableDouble(json['latitude']),
      longitude: parseNullableDouble(json['longitude']),
      pricingUnit:
          PricingUnit.fromValue(json['pricing_unit']?.toString() ?? 'DAY'),
      priceValue: _parsePriceValue(json['price_value']),
      pricePerDay: _parsePriceValue(json['price_per_day']),
      size: json['size']?.toString() ?? '',
      bedroomsNo: parseInt(json['bedrooms_no']),
      bedsNo: parseInt(json['beds_no']),
      bathroomsNo: parseInt(json['bathrooms_no']),
      images: parseList(json['images']),
      ownershipProofs: parseList(json['ownership_proofs']),
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isAvailable: json['is_available'] == true || json['is_available'] == 1,
      isFurnished: json['is_furnished'] == true || json['is_furnished'] == 1,
      isSponsored: json['is_sponsored'] == true || json['is_sponsored'] == 1,
      listingType: ListingType.fromValue(
          json['property_type']?.toString() ?? 'for_rent'),
      rate: parseNullableDouble(json['rate']),
      listingStatus:
          ListingStatus.fromValue(json['listing_status']?.toString()),
      ownerFirstName: json['owner_first_name']?.toString(),
      ownerSecondName: json['owner_second_name']?.toString(),
      ownerEmail: json['owner_email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'property_id': propertyId,
        'owner_id': ownerId,
        'property_name': propertyName,
        'property_desc': propertyDesc,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'pricing_unit': pricingUnit.value,
        'price_value': priceValue,
        'price_per_day': pricePerDay,
        'size': size,
        'bedrooms_no': bedroomsNo,
        'beds_no': bedsNo,
        'bathrooms_no': bathroomsNo,
        'images': images,
        'ownership_proofs': ownershipProofs,
        'is_verified': isVerified,
        'is_available': isAvailable,
        'is_furnished': isFurnished,
        'is_sponsored': isSponsored,
        'property_type': listingType.value,
        'rate': rate,
        'listing_status': listingStatus?.value,
      };

  static double _parsePriceValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _getFullImageUrl(String path) {
    if (path.startsWith('http')) return path;
    if (path.startsWith('uploads/')) {
      return '${AppConfig.imageBaseUrl}/$path';
    }
    if (path.startsWith('/')) {
      return '${AppConfig.imageBaseUrl}$path';
    }
    return '${AppConfig.imageBaseUrl}/uploads/$path';
  }
}
