import 'package:dartz/dartz.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/subscription/domain/entities/subscription_entity.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, SubscriptionEntity>> getSubscription(int propertyId);
  Future<Either<Failure, SubscriptionEntity>> createSubscription({
    required int propertyId,
    required int planMonths,
  });
}
