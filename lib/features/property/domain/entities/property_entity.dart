import 'property_enums.dart';

class PropertyEntity {
  final int propertyId;
  final String ownerId;
  final String propertyName;
  final String propertyDesc;
  final String location;
  final double? latitude;
  final double? longitude;
  final PricingUnit pricingUnit;
  final double priceValue;
  final double pricePerDay;
  final String size;
  final int bedroomsNo;
  final int bedsNo;
  final int bathroomsNo;
  final List<String> images;
  final List<String> ownershipProofs;
  final bool isVerified;
  final bool isAvailable;
  final bool isFurnished;
  final bool isSponsored;
  final ListingType listingType;
  final double? rate;
  final ListingStatus? listingStatus;
  final String? ownerFirstName;
  final String? ownerSecondName;
  final String? ownerEmail;

  const PropertyEntity({
    required this.propertyId,
    required this.ownerId,
    required this.propertyName,
    required this.propertyDesc,
    required this.location,
    this.latitude,
    this.longitude,
    required this.pricingUnit,
    required this.priceValue,
    required this.pricePerDay,
    required this.size,
    required this.bedroomsNo,
    required this.bedsNo,
    required this.bathroomsNo,
    required this.images,
    this.ownershipProofs = const [],
    required this.isVerified,
    required this.isAvailable,
    required this.isFurnished,
    this.isSponsored = false,
    required this.listingType,
    this.rate,
    this.listingStatus,
    this.ownerFirstName,
    this.ownerSecondName,
    this.ownerEmail,
  });

  PropertyStatus get status {
    if (isSponsored) return PropertyStatus.sponsored;
    switch (listingType) {
      case ListingType.forRent:
        return PropertyStatus.forRent;
      case ListingType.forSale:
        return PropertyStatus.forSale;
    }
  }

  String get pricingUnitSuffix {
    if (listingType == ListingType.forSale) return '';
    switch (pricingUnit) {
      case PricingUnit.day:
        return '/day';
      case PricingUnit.month:
        return '/mo';
    }
  }
}
