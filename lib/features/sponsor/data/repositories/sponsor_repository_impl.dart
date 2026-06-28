import 'package:dartz/dartz.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/features/sponsor/domain/entities/sponsor_entity.dart';
import 'package:aqar/features/sponsor/domain/repositories/sponsor_repository.dart';
import 'package:aqar/features/sponsor/data/datasources/sponsor_remote_data_source.dart';

class SponsorRepositoryImpl implements SponsorRepository {
  final SponsorRemoteDataSource remoteDataSource;
  SponsorRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, SponsorEntity>> createCheckout({
    required int propertyId,
    required int duration,
    required String redirect,
  }) async {
    try {
      final result = await remoteDataSource.createCheckout(
        propertyId: propertyId,
        duration: duration,
        redirect: redirect,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
