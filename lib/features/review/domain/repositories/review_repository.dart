import 'package:dartz/dartz.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/review/domain/entities/review_entity.dart';

abstract class ReviewRepository {
  Future<Either<Failure, List<ReviewEntity>>> getReviews({int? propertyId});
  Future<Either<Failure, void>> addReview({
    required double rating,
    required String phrase,
    int? propertyId,
    String? rentId,
    String? leaseId,
  });
}
