import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/usecases/usecase.dart';
import '../../domain/entities/rent_request_entity.dart';
import '../../domain/usecases/accept_rent_request_usecase.dart';
import '../../domain/usecases/cancel_rent_request_usecase.dart';
import '../../domain/usecases/create_rent_request_usecase.dart';
import '../../domain/usecases/get_received_requests_usecase.dart';
import '../../domain/usecases/get_sent_requests_usecase.dart';
import '../../domain/usecases/reject_rent_request_usecase.dart';
import 'rent_request_event.dart';
import 'rent_request_state.dart';

@injectable
class RentRequestBloc extends Bloc<RentRequestEvent, RentRequestState> {
  final GetSentRequestsUseCase getSentRequests;
  final GetReceivedRequestsUseCase getReceivedRequests;
  final CreateRentRequestUseCase createRequest;
  final AcceptRentRequestUseCase acceptRequest;
  final RejectRentRequestUseCase rejectRequest;
  final CancelRentRequestUseCase cancelRequest;

  RentRequestBloc({
    required this.getSentRequests,
    required this.getReceivedRequests,
    required this.createRequest,
    required this.acceptRequest,
    required this.rejectRequest,
    required this.cancelRequest,
  }) : super(RentRequestInitial()) {
    on<LoadRentRequests>(_onLoadRequests);
    on<CreateRentRequest>(_onCreateRequest);
    on<AcceptRentRequest>(_onAcceptRequest);
    on<RejectRentRequest>(_onRejectRequest);
    on<CancelRentRequest>(_onCancelRequest);
  }

  Future<void> _onLoadRequests(
    LoadRentRequests event,
    Emitter<RentRequestState> emit,
  ) async {
    emit(RentRequestLoading());

    final results = await Future.wait([
      getSentRequests(NoParams()),
      getReceivedRequests(NoParams()),
    ]);

    final sentResult = results[0];
    final receivedResult = results[1];

    final sent = sentResult.getOrElse(() => <RentRequestEntity>[]);
    final received = receivedResult.getOrElse(() => <RentRequestEntity>[]);

    if (sentResult.isLeft() && receivedResult.isLeft()) {
      final msg = sentResult.fold((f) => f.message, (_) => 'Failed to load requests');
      emit(RentRequestError(msg));
      return;
    }

    emit(RentRequestsLoaded(sent: sent, received: received));
  }

  Future<void> _onCreateRequest(
    CreateRentRequest event,
    Emitter<RentRequestState> emit,
  ) async {
    emit(RentRequestLoading());

    final result = await createRequest(CreateRentRequestParams(
      propertyId: event.propertyId,
      checkInDate: event.checkInDate,
      checkOutDate: event.checkOutDate,
      rentingType: event.rentingType,
    ));

    result.fold(
      (failure) => emit(RentRequestError(failure.message)),
      (_) {
        emit(RentRequestActionSuccess('Request sent successfully'));
        add(const LoadRentRequests());
      },
    );
  }

  Future<void> _onAcceptRequest(
    AcceptRentRequest event,
    Emitter<RentRequestState> emit,
  ) async {
    emit(RentRequestLoading());

    final result = await acceptRequest(event.requestId);

    result.fold(
      (failure) => emit(RentRequestError(failure.message)),
      (_) {
        emit(RentRequestActionSuccess('Request accepted'));
        add(const LoadRentRequests());
      },
    );
  }

  Future<void> _onRejectRequest(
    RejectRentRequest event,
    Emitter<RentRequestState> emit,
  ) async {
    emit(RentRequestLoading());

    final result = await rejectRequest(event.requestId);

    result.fold(
      (failure) => emit(RentRequestError(failure.message)),
      (_) {
        emit(RentRequestActionSuccess('Request rejected'));
        add(const LoadRentRequests());
      },
    );
  }

  Future<void> _onCancelRequest(
    CancelRentRequest event,
    Emitter<RentRequestState> emit,
  ) async {
    emit(RentRequestLoading());

    final result = await cancelRequest(event.requestId);

    result.fold(
      (failure) => emit(RentRequestError(failure.message)),
      (_) {
        emit(RentRequestActionSuccess('Request cancelled'));
        add(const LoadRentRequests());
      },
    );
  }
}
