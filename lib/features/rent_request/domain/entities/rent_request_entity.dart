import 'rent_request_enums.dart';

class RentRequestEntity {
  final String requestId;
  final int propertyId;
  final String renterId;
  final RentingType rentingType;
  final RentRequestState state;
  final double totalPrice;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final DateTime createdAt;
  final String? propertyName;
  final String? perspective;
  final String? ownerId;
  final String? paymentId;

  const RentRequestEntity({
    required this.requestId,
    required this.propertyId,
    required this.renterId,
    required this.rentingType,
    required this.state,
    required this.totalPrice,
    required this.checkInDate,
    required this.checkOutDate,
    required this.createdAt,
    this.propertyName,
    this.perspective,
    this.ownerId,
    this.paymentId,
  });
}
