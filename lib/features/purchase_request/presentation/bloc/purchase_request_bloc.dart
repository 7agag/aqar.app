import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/purchase_request/domain/entities/purchase_request_entity.dart';
import 'package:aqar/features/purchase_request/domain/usecases/get_my_purchase_requests_usecase.dart';
import 'package:aqar/features/purchase_request/domain/usecases/get_received_purchase_requests_usecase.dart';
import 'package:aqar/features/purchase_request/domain/usecases/create_purchase_request_usecase.dart';
import 'package:aqar/features/purchase_request/domain/usecases/update_purchase_request_status_usecase.dart';
import 'package:aqar/features/purchase_request/domain/usecases/cancel_purchase_request_usecase.dart';
import 'package:aqar/features/purchase_request/domain/usecases/mark_property_sold_usecase.dart';

// Events
abstract class PurchaseRequestEvent extends Equatable {
  const PurchaseRequestEvent();
  @override
  List<Object?> get props => [];
}

class GetMyRequests extends PurchaseRequestEvent {}

class GetReceivedRequests extends PurchaseRequestEvent {}

class CreateRequest extends PurchaseRequestEvent {
  final int propertyId;
  final String? message;
  const CreateRequest({required this.propertyId, this.message});
  @override
  List<Object?> get props => [propertyId, message];
}

class UpdateRequestStatus extends PurchaseRequestEvent {
  final String requestId;
  final String status;
  const UpdateRequestStatus({required this.requestId, required this.status});
  @override
  List<Object?> get props => [requestId, status];
}

class CancelRequest extends PurchaseRequestEvent {
  final String requestId;
  const CancelRequest({required this.requestId});
  @override
  List<Object?> get props => [requestId];
}

class MarkPropertySold extends PurchaseRequestEvent {
  final int propertyId;
  const MarkPropertySold({required this.propertyId});
  @override
  List<Object?> get props => [propertyId];
}

// States
abstract class PurchaseRequestState extends Equatable {
  const PurchaseRequestState();
  @override
  List<Object?> get props => [];
}

class PurchaseRequestInitial extends PurchaseRequestState {}

class PurchaseRequestLoading extends PurchaseRequestState {}

class MyRequestsLoaded extends PurchaseRequestState {
  final List<PurchaseRequestEntity> requests;
  const MyRequestsLoaded(this.requests);
  @override
  List<Object?> get props => [requests];
}

class ReceivedRequestsLoaded extends PurchaseRequestState {
  final List<PurchaseRequestEntity> requests;
  const ReceivedRequestsLoaded(this.requests);
  @override
  List<Object?> get props => [requests];
}

class PurchaseRequestSuccess extends PurchaseRequestState {
  final String message;
  const PurchaseRequestSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class PurchaseRequestError extends PurchaseRequestState {
  final String message;
  const PurchaseRequestError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class PurchaseRequestBloc
    extends Bloc<PurchaseRequestEvent, PurchaseRequestState> {
  final GetMyPurchaseRequestsUseCase getMyRequestsUseCase;
  final GetReceivedPurchaseRequestsUseCase getReceivedRequestsUseCase;
  final CreatePurchaseRequestUseCase createRequestUseCase;
  final UpdatePurchaseRequestStatusUseCase updateStatusUseCase;
  final CancelPurchaseRequestUseCase cancelRequestUseCase;
  final MarkPropertySoldUseCase markPropertySoldUseCase;

  PurchaseRequestBloc({
    required this.getMyRequestsUseCase,
    required this.getReceivedRequestsUseCase,
    required this.createRequestUseCase,
    required this.updateStatusUseCase,
    required this.cancelRequestUseCase,
    required this.markPropertySoldUseCase,
  }) : super(PurchaseRequestInitial()) {
    on<GetMyRequests>(_onGetMyRequests);
    on<GetReceivedRequests>(_onGetReceivedRequests);
    on<CreateRequest>(_onCreateRequest);
    on<UpdateRequestStatus>(_onUpdateStatus);
    on<CancelRequest>(_onCancel);
    on<MarkPropertySold>(_onMarkSold);
  }

  Future<void> _onGetMyRequests(
      GetMyRequests event, Emitter<PurchaseRequestState> emit) async {
    emit(PurchaseRequestLoading());
    final result = await getMyRequestsUseCase(NoParams());
    result.fold(
      (failure) => emit(PurchaseRequestError(_mapFailure(failure))),
      (requests) => emit(MyRequestsLoaded(requests)),
    );
  }

  Future<void> _onGetReceivedRequests(
      GetReceivedRequests event, Emitter<PurchaseRequestState> emit) async {
    emit(PurchaseRequestLoading());
    final result = await getReceivedRequestsUseCase(NoParams());
    result.fold(
      (failure) => emit(PurchaseRequestError(_mapFailure(failure))),
      (requests) => emit(ReceivedRequestsLoaded(requests)),
    );
  }

  Future<void> _onCreateRequest(
      CreateRequest event, Emitter<PurchaseRequestState> emit) async {
    emit(PurchaseRequestLoading());
    final result = await createRequestUseCase(
      CreatePurchaseRequestParams(
        propertyId: event.propertyId,
        message: event.message,
      ),
    );
    result.fold(
      (failure) => emit(PurchaseRequestError(_mapFailure(failure))),
      (msg) => emit(PurchaseRequestSuccess(msg)),
    );
  }

  Future<void> _onUpdateStatus(
      UpdateRequestStatus event, Emitter<PurchaseRequestState> emit) async {
    emit(PurchaseRequestLoading());
    final result = await updateStatusUseCase(
      UpdatePurchaseRequestStatusParams(
        requestId: event.requestId,
        status: event.status,
      ),
    );
    result.fold(
      (failure) => emit(PurchaseRequestError(_mapFailure(failure))),
      (msg) => emit(PurchaseRequestSuccess(msg)),
    );
  }

  Future<void> _onCancel(
      CancelRequest event, Emitter<PurchaseRequestState> emit) async {
    emit(PurchaseRequestLoading());
    final result = await cancelRequestUseCase(
      CancelPurchaseRequestParams(requestId: event.requestId),
    );
    result.fold(
      (failure) => emit(PurchaseRequestError(_mapFailure(failure))),
      (msg) => emit(PurchaseRequestSuccess(msg)),
    );
  }

  Future<void> _onMarkSold(
      MarkPropertySold event, Emitter<PurchaseRequestState> emit) async {
    emit(PurchaseRequestLoading());
    final result = await markPropertySoldUseCase(
      MarkPropertySoldParams(propertyId: event.propertyId),
    );
    result.fold(
      (failure) => emit(PurchaseRequestError(_mapFailure(failure))),
      (msg) => emit(PurchaseRequestSuccess(msg)),
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is ServerFailure) return failure.message;
    if (failure is UnauthorizedFailure) return 'Session expired. Please sign in again.';
    return 'Something went wrong';
  }
}
