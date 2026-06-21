import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/review/domain/entities/review_entity.dart';
import 'package:aqar/features/review/domain/usecases/get_reviews_usecase.dart';
import 'package:aqar/features/review/domain/usecases/add_review_usecase.dart';

// Events
abstract class ReviewEvent extends Equatable {
  const ReviewEvent();
  @override
  List<Object?> get props => [];
}

class GetReviews extends ReviewEvent {
  final int? propertyId;
  const GetReviews({this.propertyId});
  @override
  List<Object?> get props => [propertyId];
}

class AddReview extends ReviewEvent {
  final double rating;
  final String phrase;
  final int? propertyId;
  final String? rentId;
  final String? leaseId;
  const AddReview({
    required this.rating,
    this.phrase = '',
    this.propertyId,
    this.rentId,
    this.leaseId,
  });
  @override
  List<Object?> get props => [rating, phrase, propertyId, rentId, leaseId];
}

// States
abstract class ReviewState extends Equatable {
  const ReviewState();
  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewsLoaded extends ReviewState {
  final List<ReviewEntity> reviews;
  const ReviewsLoaded(this.reviews);
  @override
  List<Object?> get props => [reviews];
}

class ReviewAdded extends ReviewState {
  final String message;
  const ReviewAdded(this.message);
  @override
  List<Object?> get props => [message];
}

class ReviewError extends ReviewState {
  final String message;
  const ReviewError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final GetReviewsUseCase getReviewsUseCase;
  final AddReviewUseCase addReviewUseCase;

  ReviewBloc({
    required this.getReviewsUseCase,
    required this.addReviewUseCase,
  }) : super(ReviewInitial()) {
    on<GetReviews>(_onGetReviews);
    on<AddReview>(_onAddReview);
  }

  Future<void> _onGetReviews(
      GetReviews event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    final result = await getReviewsUseCase(
      GetReviewsParams(propertyId: event.propertyId),
    );
    result.fold(
      (failure) => emit(ReviewError(_mapFailure(failure))),
      (reviews) => emit(ReviewsLoaded(reviews)),
    );
  }

  Future<void> _onAddReview(
      AddReview event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    final result = await addReviewUseCase(
      AddReviewParams(
        rating: event.rating,
        phrase: event.phrase,
        propertyId: event.propertyId,
        rentId: event.rentId,
        leaseId: event.leaseId,
      ),
    );
    result.fold(
      (failure) => emit(ReviewError(_mapFailure(failure))),
      (_) => emit(const ReviewAdded('Review added successfully')),
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is ServerFailure) return failure.message;
    return 'Something went wrong';
  }
}
