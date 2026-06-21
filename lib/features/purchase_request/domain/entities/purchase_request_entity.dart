import 'package:equatable/equatable.dart';

class PurchaseRequestEntity extends Equatable {
  final String requestId;
  final int? propertyId;
  final String? propertyName;
  final String? images;
  final String? listingStatus;
  final String status;
  final String? message;
  final bool contactUnlocked;
  final DateTime createdAt;

  final String? buyerId;
  final String? buyerFirstName;
  final String? buyerSecondName;
  final String? buyerEmail;

  final String? ownerFirstName;
  final String? ownerSecondName;

  const PurchaseRequestEntity({
    required this.requestId,
    this.propertyId,
    this.propertyName,
    this.images,
    this.listingStatus,
    required this.status,
    this.message,
    this.contactUnlocked = false,
    required this.createdAt,
    this.buyerId,
    this.buyerFirstName,
    this.buyerSecondName,
    this.buyerEmail,
    this.ownerFirstName,
    this.ownerSecondName,
  });

  factory PurchaseRequestEntity.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestEntity(
      requestId: (json['request_id'] as int?)?.toString() ??
          json['request_id'] as String? ?? '',
      propertyId: json['property_id'] as int?,
      propertyName: json['property_name'] as String?,
      images: json['images'] as String?,
      listingStatus: json['listing_status'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      message: json['message'] as String?,
      contactUnlocked: json['contact_unlocked'] == true ||
          json['contact_unlocked'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      buyerId: json['buyer_id'] as String?,
      buyerFirstName: json['buyer_first_name'] as String?,
      buyerSecondName: json['buyer_second_name'] as String?,
      buyerEmail: json['buyer_email'] as String?,
      ownerFirstName: json['owner_first_name'] as String?,
      ownerSecondName: json['owner_second_name'] as String?,
    );
  }

  String get buyerName {
    if (buyerFirstName != null && buyerSecondName != null) {
      return '$buyerFirstName $buyerSecondName';
    }
    return buyerFirstName ?? buyerId ?? 'Unknown';
  }

  String get ownerName {
    if (ownerFirstName != null && ownerSecondName != null) {
      return '$ownerFirstName $ownerSecondName';
    }
    return ownerFirstName ?? 'Owner';
  }

  @override
  List<Object?> get props => [
    requestId, propertyId, propertyName, images, listingStatus, status,
    message, contactUnlocked, createdAt, buyerId, buyerFirstName,
    buyerSecondName, buyerEmail, ownerFirstName, ownerSecondName,
  ];
}
