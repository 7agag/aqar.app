import '../../domain/entities/rent_request_entity.dart';
import '../../domain/entities/rent_request_enums.dart';

class RentRequestModel extends RentRequestEntity {
  const RentRequestModel({
    required super.requestId,
    required super.propertyId,
    required super.renterId,
    required super.rentingType,
    required super.state,
    required super.totalPrice,
    required super.checkInDate,
    required super.checkOutDate,
    required super.createdAt,
    super.propertyName,
    super.perspective,
    super.ownerId,
    super.paymentId,
  });

  factory RentRequestModel.fromJson(Map<String, dynamic> json) {
    return RentRequestModel(
      requestId: json['request_id'] as String,
      propertyId: json['property_id'] as int,
      renterId: json['renter_id'] as String,
      rentingType: RentingType.fromValue(json['renting_type'] as String),
      state: RentRequestState.fromValue(json['request_state'] as String),
      totalPrice: (json['total_price'] as num).toDouble(),
      checkInDate: DateTime.parse(json['check_in_date'] as String),
      checkOutDate: DateTime.parse(json['check_out_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      propertyName: json['property_name'] as String?,
      perspective: json['perspective'] as String?,
      ownerId: json['owner_id'] as String?,
      paymentId: json['payment_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'property_id': propertyId,
        'renter_id': renterId,
        'renting_type': rentingType.value,
        'request_state': state.name.toUpperCase(),
        'total_price': totalPrice,
        'check_in_date': checkInDate.toIso8601String().substring(0, 10),
        'check_out_date': checkOutDate.toIso8601String().substring(0, 10),
        'created_at': createdAt.toIso8601String(),
        if (propertyName != null) 'property_name': propertyName,
        if (perspective != null) 'perspective': perspective,
        if (ownerId != null) 'owner_id': ownerId,
        if (paymentId != null) 'payment_id': paymentId,
      };
}

class RentRequestListModel {
  final List<RentRequestModel> sent;
  final List<RentRequestModel> received;

  const RentRequestListModel({required this.sent, required this.received});

  factory RentRequestListModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return RentRequestListModel(
      sent: (data['sent'] as List)
          .map((e) => RentRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      received: (data['received'] as List)
          .map((e) => RentRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
