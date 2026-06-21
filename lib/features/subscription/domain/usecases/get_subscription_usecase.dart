import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/subscription/domain/entities/subscription_entity.dart';
import 'package:aqar/features/subscription/domain/repositories/subscription_repository.dart';

@injectable
class GetSubscriptionUseCase
    extends UseCase<SubscriptionEntity, GetSubscriptionParams> {
  final SubscriptionRepository repository;
  GetSubscriptionUseCase(this.repository);

  @override
  Future<Either<Failure, SubscriptionEntity>> call(
      GetSubscriptionParams params) {
    return repository.getSubscription(params.propertyId);
  }
}

class GetSubscriptionParams extends Equatable {
  final int propertyId;
  const GetSubscriptionParams({required this.propertyId});
  @override
  List<Object?> get props => [propertyId];
}
