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
      requestId: json['request_id']?.toString() ?? '',
      propertyId: _parseInt(json['property_id']),
      renterId: json['renter_id']?.toString() ?? '',
      rentingType: RentingType.fromValue(json['renting_type']?.toString() ?? ''),
      state: RentRequestState.fromValue(json['request_state']?.toString() ?? ''),
      totalPrice: _parseDouble(json['total_price']),
      checkInDate: DateTime.tryParse(json['check_in_date']?.toString() ?? '') ?? DateTime.now(),
      checkOutDate: DateTime.tryParse(json['check_out_date']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      propertyName: json['property_name']?.toString(),
      perspective: json['perspective']?.toString(),
      ownerId: json['owner_id']?.toString(),
      paymentId: json['payment_id']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      return const RentRequestListModel(sent: [], received: []);
    }
    List<RentRequestModel> parseList(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(RentRequestModel.fromJson)
          .toList();
    }
    return RentRequestListModel(
      sent: parseList(data['sent']),
      received: parseList(data['received']),
    );
  }

  factory RentRequestListModel.fromList(List<dynamic> list) {
    final models = list
        .whereType<Map<String, dynamic>>()
        .map(RentRequestModel.fromJson)
        .toList();
    return RentRequestListModel(sent: models, received: models);
  }
}
