import 'package:dartz/dartz.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/features/review/domain/entities/review_entity.dart';
import 'package:aqar/features/review/domain/repositories/review_repository.dart';
import 'package:aqar/features/review/data/datasources/review_remote_data_source.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;
  ReviewRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ReviewEntity>>> getReviews(
      {int? propertyId}) async {
    try {
      final result = await remoteDataSource.getReviews(propertyId: propertyId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addReview({
    required double rating,
    required String phrase,
    int? propertyId,
    String? rentId,
    String? leaseId,
  }) async {
    try {
      await remoteDataSource.addReview(
        rating: rating,
        phrase: phrase,
        propertyId: propertyId,
        rentId: rentId,
        leaseId: leaseId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
