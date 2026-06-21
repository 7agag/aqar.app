import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/review/domain/repositories/review_repository.dart';

@injectable
class AddReviewUseCase extends UseCase<void, AddReviewParams> {
  final ReviewRepository repository;
  AddReviewUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddReviewParams params) {
    return repository.addReview(
      rating: params.rating,
      phrase: params.phrase,
      propertyId: params.propertyId,
      rentId: params.rentId,
      leaseId: params.leaseId,
    );
  }
}

class AddReviewParams extends Equatable {
  final double rating;
  final String phrase;
  final int? propertyId;
  final String? rentId;
  final String? leaseId;
  const AddReviewParams({
    required this.rating,
    this.phrase = '',
    this.propertyId,
    this.rentId,
    this.leaseId,
  });
  @override
  List<Object?> get props => [rating, phrase, propertyId, rentId, leaseId];
}
