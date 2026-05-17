import '../../domain/entities/property_entity.dart';

class PropertyModel extends PropertyEntity {
  const PropertyModel({
    required super.id,
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
    required super.ownershipProofs,
    required super.isVerified,
    required super.isAvailable,
    required super.isFurnished,
    required super.propertyType,
    super.rate,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['property_id'] ?? 0,
      ownerId: json['owner_id'] ?? '',
      propertyName: json['property_name'] ?? '',
      propertyDesc: json['property_desc'] ?? '',
      location: json['location'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      pricingUnit: json['pricing_unit'] ?? 'DAY',
      priceValue: double.tryParse(json['price_value'].toString()) ?? 0.0,
      pricePerDay: double.tryParse(json['price_per_day'].toString()) ?? 0.0,
      size: json['size']?.toString() ?? '',
      bedroomsNo: json['bedrooms_no'] ?? 0,
      bedsNo: json['beds_no'] ?? 0,
      bathroomsNo: json['bathrooms_no'] ?? 0,
      images: _parseList(json['images']),
      ownershipProofs: _parseList(json['ownership_proofs']),
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      isFurnished: json['is_furnished'] == 1 || json['is_furnished'] == true,
      propertyType: json['property_type'] ?? 'for_rent',
      rate: json['rate'] != null
          ? double.tryParse(json['rate'].toString())
          : null,
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    return [];
  }
}