import 'package:equatable/equatable.dart';

abstract class RentRequestEvent extends Equatable {
  const RentRequestEvent();
  @override
  List<Object?> get props => [];
}

class LoadRentRequests extends RentRequestEvent {
  const LoadRentRequests();
}

class CreateRentRequest extends RentRequestEvent {
  final int propertyId;
  final String checkInDate;
  final String checkOutDate;
  final String rentingType;

  const CreateRentRequest({
    required this.propertyId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.rentingType,
  });

  @override
  List<Object?> get props => [propertyId, checkInDate, checkOutDate, rentingType];
}

class AcceptRentRequest extends RentRequestEvent {
  final String requestId;
  const AcceptRentRequest({required this.requestId});
  @override
  List<Object?> get props => [requestId];
}

class RejectRentRequest extends RentRequestEvent {
  final String requestId;
  const RejectRentRequest({required this.requestId});
  @override
  List<Object?> get props => [requestId];
}

class CancelRentRequest extends RentRequestEvent {
  final String requestId;
  const CancelRentRequest({required this.requestId});
  @override
  List<Object?> get props => [requestId];
}

class GetRentRequestById extends RentRequestEvent {
  final String requestId;
  const GetRentRequestById({required this.requestId});
  @override
  List<Object?> get props => [requestId];
}
