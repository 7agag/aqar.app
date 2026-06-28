import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/sponsor/domain/entities/sponsor_entity.dart';
import 'package:aqar/features/sponsor/domain/repositories/sponsor_repository.dart';

@injectable
class CreateSponsorCheckoutUseCase
    extends UseCase<SponsorEntity, CreateSponsorCheckoutParams> {
  final SponsorRepository repository;
  CreateSponsorCheckoutUseCase(this.repository);

  @override
  Future<Either<Failure, SponsorEntity>> call(
      CreateSponsorCheckoutParams params) {
    return repository.createCheckout(
      propertyId: params.propertyId,
      duration: params.duration,
      redirect: params.redirect,
    );
  }
}

class CreateSponsorCheckoutParams extends Equatable {
  final int propertyId;
  final int duration;
  final String redirect;

  const CreateSponsorCheckoutParams({
    required this.propertyId,
    required this.duration,
    required this.redirect,
  });

  @override
  List<Object?> get props => [propertyId, duration, redirect];
}
