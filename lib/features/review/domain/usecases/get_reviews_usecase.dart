import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/review/domain/entities/review_entity.dart';
import 'package:aqar/features/review/domain/repositories/review_repository.dart';

@injectable
class GetReviewsUseCase
    extends UseCase<List<ReviewEntity>, GetReviewsParams> {
  final ReviewRepository repository;
  GetReviewsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ReviewEntity>>> call(
      GetReviewsParams params) {
    return repository.getReviews(propertyId: params.propertyId);
  }
}

class GetReviewsParams extends Equatable {
  final int? propertyId;
  const GetReviewsParams({this.propertyId});
  @override
  List<Object?> get props => [propertyId];
}
