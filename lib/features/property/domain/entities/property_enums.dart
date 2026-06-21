import 'package:flutter/painting.dart';

enum ListingType {
  forSale('for_sale', 'For Sale'),
  forRent('for_rent', 'For Rent');

  final String value;
  final String label;
  const ListingType(this.value, this.label);
  static ListingType fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => forRent);
}

enum ListingStatus {
  inactive('inactive', 'Inactive'),
  active('active', 'Active'),
  underNegotiation('under_negotiation', 'Under Negotiation'),
  sold('sold', 'Sold'),
  expired('expired', 'Expired');

  final String value;
  final String label;
  const ListingStatus(this.value, this.label);
  static ListingStatus fromValue(String? v) =>
      values.firstWhere((e) => e.value == v, orElse: () => inactive);
}

enum PropertyStatus {
  forSale('for_sale', 'For Sale', Color(0xFF1A2744)),
  forRent('for_rent', 'For Rent', Color(0xFF1D9E75)),
  sponsored('sponsored', 'Sponsored', Color(0xFFD4AF37)),
  pending('pending', 'Pending Verification', Color(0xFFFFA000)),
  archived('archived', 'Archived', Color(0xFF9E9E9E));

  final String value;
  final String label;
  final Color color;
  const PropertyStatus(this.value, this.label, this.color);
  static PropertyStatus fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => forRent);
}

enum PropertyViewType {
  ownerOfRent,
  ownerOfSale,
  tenantRent,
  buyerSale;

  bool get isOwner => this == ownerOfRent || this == ownerOfSale;
}

enum RentPeriod {
  daily('DAY', 'Daily / يومي'),
  monthly('MONTH', 'Monthly / شهري');

  final String value;
  final String label;
  const RentPeriod(this.value, this.label);
}

enum PricingUnit {
  day('DAY', 'day'),
  month('MONTH', 'month'),
  year('YEAR', 'year');

  final String value;
  final String label;
  const PricingUnit(this.value, this.label);
  static PricingUnit fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => day);
}
