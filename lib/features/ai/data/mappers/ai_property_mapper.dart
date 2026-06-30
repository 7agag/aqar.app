import '../../../../core/config/app_config.dart';
import '../../../property/domain/entities/property_entity.dart';
import '../../../property/domain/entities/property_enums.dart';

PropertyEntity mapAiPropertyToEntity(Map<String, dynamic> json) {
  final imagesRaw = json['images'];
  List<String> images;
  if (imagesRaw is List) {
    images = imagesRaw.map((e) => e.toString()).toList();
  } else if (imagesRaw is String && imagesRaw.isNotEmpty) {
    images = [imagesRaw];
  } else {
    images = [];
  }
  images = images.map((url) {
    if (url.startsWith('http')) return url;
    return '${AppConfig.imageBaseUrl}$url';
  }).toList();

  return PropertyEntity(
    propertyId: int.tryParse(json['property_id']?.toString() ?? '') ??
        (json['property_id'] as num?)?.toInt() ?? 0,
    ownerId: json['owner_id']?.toString() ?? '',
    propertyName: json['property_name'] as String? ?? json['title'] as String? ?? 'Listing',
    propertyDesc: json['property_desc'] as String? ?? '',
    location: json['location'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    pricingUnit: PricingUnit.fromValue(json['pricing_unit'] as String? ?? 'MONTH'),
    priceValue: (json['price_value'] as num?)?.toDouble() ?? 0,
    pricePerDay: (json['price_per_day'] as num?)?.toDouble() ?? (json['price_value'] as num?)?.toDouble() ?? 0,
    size: json['size']?.toString() ?? '',
    bedroomsNo: (json['bedrooms_no'] as num?)?.toInt() ?? 0,
    bedsNo: (json['beds_no'] as num?)?.toInt() ?? 0,
    bathroomsNo: (json['bathrooms_no'] as num?)?.toInt() ?? 0,
    images: images,
    isVerified: json['is_verified'] == true,
    isAvailable: json['is_available'] == true,
    isFurnished: json['is_furnished'] == true,
    isSponsored: json['is_sponsored'] == true,
    isVisible: json['is_visible'] != false,
    listingType: ListingType.fromValue(json['listing_type'] as String? ?? 'for_rent'),
    listingStatus: json['listing_status'] != null
        ? ListingStatus.fromValue(json['listing_status'] as String?)
        : null,
    rate: (json['rate'] as num?)?.toDouble(),
    listingExpiry: json['listing_expiry'] != null
        ? DateTime.tryParse(json['listing_expiry'] as String)
        : null,
    ownerFirstName: json['owner_first_name'] as String?,
    ownerSecondName: json['owner_second_name'] as String?,
    ownerEmail: json['owner_email'] as String?,
  );
}
