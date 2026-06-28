import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/sponsor/domain/usecases/create_sponsor_checkout_usecase.dart';

abstract class SponsorEvent extends Equatable {
  const SponsorEvent();
  @override
  List<Object?> get props => [];
}

class CreateSponsorCheckout extends SponsorEvent {
  final int propertyId;
  final int duration;
  final String redirect;

  const CreateSponsorCheckout({
    required this.propertyId,
    required this.duration,
    required this.redirect,
  });

  @override
  List<Object?> get props => [propertyId, duration, redirect];
}

class ResetSponsor extends SponsorEvent {}

abstract class SponsorState extends Equatable {
  const SponsorState();
  @override
  List<Object?> get props => [];
}

class SponsorInitial extends SponsorState {}

class SponsorLoading extends SponsorState {}

class SponsorCheckoutReady extends SponsorState {
  final String url;
  const SponsorCheckoutReady(this.url);
  @override
  List<Object?> get props => [url];
}

class SponsorError extends SponsorState {
  final String message;
  const SponsorError(this.message);
  @override
  List<Object?> get props => [message];
}

class SponsorBloc extends Bloc<SponsorEvent, SponsorState> {
  final CreateSponsorCheckoutUseCase createCheckoutUseCase;

  SponsorBloc({
    required this.createCheckoutUseCase,
  }) : super(SponsorInitial()) {
    on<CreateSponsorCheckout>(_onCreateCheckout);
    on<ResetSponsor>((_, emit) => emit(SponsorInitial()));
  }

  Future<void> _onCreateCheckout(
      CreateSponsorCheckout event, Emitter<SponsorState> emit) async {
    emit(SponsorLoading());
    final result = await createCheckoutUseCase(
      CreateSponsorCheckoutParams(
        propertyId: event.propertyId,
        duration: event.duration,
        redirect: event.redirect,
      ),
    );
    result.fold(
      (failure) => emit(SponsorError(_mapFailure(failure))),
      (sponsor) {
        if (sponsor.checkoutUrl != null) {
          emit(SponsorCheckoutReady(sponsor.checkoutUrl!));
        } else {
          emit(const SponsorError('No checkout URL returned'));
        }
      },
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is ServerFailure) return failure.message;
    return 'Something went wrong';
  }
}
