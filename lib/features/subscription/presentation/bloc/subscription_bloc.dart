import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/subscription/domain/entities/subscription_entity.dart';
import 'package:aqar/features/subscription/domain/usecases/get_subscription_usecase.dart';
import 'package:aqar/features/subscription/domain/usecases/create_subscription_usecase.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class GetSubscription extends SubscriptionEvent {
  final int propertyId;
  const GetSubscription({required this.propertyId});
  @override
  List<Object?> get props => [propertyId];
}

class CreateSubscription extends SubscriptionEvent {
  final int propertyId;
  final int planMonths;
  const CreateSubscription({
    required this.propertyId,
    required this.planMonths,
  });
  @override
  List<Object?> get props => [propertyId, planMonths];
}

class ResetSubscription extends SubscriptionEvent {}

// States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final SubscriptionEntity subscription;
  const SubscriptionLoaded(this.subscription);
  @override
  List<Object?> get props => [subscription];
}

class SubscriptionCreated extends SubscriptionState {
  final SubscriptionEntity subscription;
  const SubscriptionCreated(this.subscription);
  @override
  List<Object?> get props => [subscription];
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
  @override
  List<Object?> get props => [message];
}

class SubscriptionNotFound extends SubscriptionState {}

// Bloc
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetSubscriptionUseCase getSubscriptionUseCase;
  final CreateSubscriptionUseCase createSubscriptionUseCase;

  SubscriptionBloc({
    required this.getSubscriptionUseCase,
    required this.createSubscriptionUseCase,
  }) : super(SubscriptionInitial()) {
    on<GetSubscription>(_onGetSubscription);
    on<CreateSubscription>(_onCreateSubscription);
    on<ResetSubscription>((_, emit) => emit(SubscriptionInitial()));
  }

  Future<void> _onGetSubscription(
      GetSubscription event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    final result = await getSubscriptionUseCase(
      GetSubscriptionParams(propertyId: event.propertyId),
    );
    result.fold(
      (failure) {
        if (failure is ServerFailure &&
            failure.message.contains('No subscription found')) {
          emit(SubscriptionNotFound());
        } else {
          emit(SubscriptionError(_mapFailure(failure)));
        }
      },
      (sub) => emit(SubscriptionLoaded(sub)),
    );
  }

  Future<void> _onCreateSubscription(
      CreateSubscription event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    final result = await createSubscriptionUseCase(
      CreateSubscriptionParams(
        propertyId: event.propertyId,
        planMonths: event.planMonths,
      ),
    );
    result.fold(
      (failure) => emit(SubscriptionError(_mapFailure(failure))),
      (sub) => emit(SubscriptionCreated(sub)),
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is ServerFailure) return failure.message;
    return 'Something went wrong';
  }
}
