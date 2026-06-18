import 'package:equatable/equatable.dart';
import '../../domain/entities/rent_request_entity.dart';

abstract class RentRequestState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RentRequestInitial extends RentRequestState {}

class RentRequestLoading extends RentRequestState {}

class RentRequestsLoaded extends RentRequestState {
  final List<RentRequestEntity> sent;
  final List<RentRequestEntity> received;

  RentRequestsLoaded({required this.sent, required this.received});

  @override
  List<Object?> get props => [sent, received];
}

class RentRequestActionSuccess extends RentRequestState {
  final String message;
  RentRequestActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class RentRequestError extends RentRequestState {
  final String message;
  RentRequestError(this.message);
  @override
  List<Object?> get props => [message];
}
