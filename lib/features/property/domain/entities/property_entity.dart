import 'package:equatable/equatable.dart';

class PropertyEntity extends Equatable {
  final int id;
  final String ownerId;
  final String propertyName;
  final String propertyDesc;
  final String location;
  final double? latitude;
  final double? longitude;
  final String pricingUnit;
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
  final String propertyType;
  final double? rate;

  const PropertyEntity({
    required this.id,
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
    required this.ownershipProofs,
    required this.isVerified,
    required this.isAvailable,
    required this.isFurnished,
    required this.propertyType,
    this.rate,
  });

  @override
  List<Object?> get props => [id, ownerId];
}