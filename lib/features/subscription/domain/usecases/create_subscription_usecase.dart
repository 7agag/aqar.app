import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/subscription/domain/entities/subscription_entity.dart';
import 'package:aqar/features/subscription/domain/repositories/subscription_repository.dart';

@injectable
class CreateSubscriptionUseCase
    extends UseCase<SubscriptionEntity, CreateSubscriptionParams> {
  final SubscriptionRepository repository;
  CreateSubscriptionUseCase(this.repository);

  @override
  Future<Either<Failure, SubscriptionEntity>> call(
      CreateSubscriptionParams params) {
    return repository.createSubscription(
      propertyId: params.propertyId,
      planMonths: params.planMonths,
    );
  }
}

class CreateSubscriptionParams extends Equatable {
  final int propertyId;
  final int planMonths;
  const CreateSubscriptionParams({
    required this.propertyId,
    required this.planMonths,
  });
  @override
  List<Object?> get props => [propertyId, planMonths];
}
