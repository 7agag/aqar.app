import 'package:equatable/equatable.dart';

class LeaseEntity extends Equatable {
  final String leaseId;
  final String requestId;
  final String renterId;
  final String ownerId;
  final int propertyId;
  final String rentingType;
  final String status;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final DateTime? nextBillingDate;

  final String? renterName;
  final String? propertyName;
  final String? location;
  final String? images;
  final double? priceValue;

  const LeaseEntity({
    required this.leaseId,
    required this.requestId,
    required this.renterId,
    required this.ownerId,
    required this.propertyId,
    required this.rentingType,
    required this.status,
    required this.checkInDate,
    required this.checkOutDate,
    this.nextBillingDate,
    this.renterName,
    this.propertyName,
    this.location,
    this.images,
    this.priceValue,
  });

  factory LeaseEntity.fromJson(Map<String, dynamic> json) {
    return LeaseEntity(
      leaseId: json['lease_id'] as String? ?? '',
      requestId: json['request_id'] as String? ?? '',
      renterId: json['renter_id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      propertyId: json['property_id'] as int? ?? 0,
      rentingType: json['renting_type'] as String? ?? 'MONTH',
      status: json['status'] as String? ?? 'UPCOMING',
      checkInDate: json['check_in_date'] != null
          ? DateTime.tryParse(json['check_in_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      checkOutDate: json['check_out_date'] != null
          ? DateTime.tryParse(json['check_out_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      nextBillingDate: json['next_billing_date'] != null
          ? DateTime.tryParse(json['next_billing_date'] as String)
          : null,
      renterName: json['renter_name'] as String?,
      propertyName: json['property_name'] as String?,
      location: json['location'] as String?,
      images: json['images'] as String?,
      priceValue: json['price_value'] != null
          ? (json['price_value'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'lease_id': leaseId,
    'request_id': requestId,
    'renter_id': renterId,
    'owner_id': ownerId,
    'property_id': propertyId,
    'renting_type': rentingType,
    'status': status,
    'check_in_date': checkInDate.toIso8601String().split('T')[0],
    'check_out_date': checkOutDate.toIso8601String().split('T')[0],
    'next_billing_date': nextBillingDate?.toIso8601String().split('T')[0],
    'renter_name': renterName,
    'property_name': propertyName,
    'location': location,
    'images': images,
    'price_value': priceValue,
  };

  @override
  List<Object?> get props => [
    leaseId, requestId, renterId, ownerId, propertyId, rentingType,
    status, checkInDate, checkOutDate, nextBillingDate,
    renterName, propertyName, location, images, priceValue,
  ];
}
