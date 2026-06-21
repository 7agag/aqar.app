import 'package:dartz/dartz.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/features/subscription/domain/entities/subscription_entity.dart';
import 'package:aqar/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:aqar/features/subscription/data/datasources/subscription_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;
  SubscriptionRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, SubscriptionEntity>> getSubscription(
      int propertyId) async {
    try {
      final result = await remoteDataSource.getSubscription(propertyId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> createSubscription({
    required int propertyId,
    required int planMonths,
  }) async {
    try {
      final result = await remoteDataSource.createSubscription(
        propertyId: propertyId,
        planMonths: planMonths,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
