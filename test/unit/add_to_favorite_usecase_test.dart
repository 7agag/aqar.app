import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/favorite/domain/repositories/favorite_repository.dart';
import 'package:aqar/features/favorite/domain/usecases/add_to_favorite_usecase.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';

class MockFavoriteRepository extends FavoriteRepository {
  Either<Failure, void> _result = const Right(null);

  void setResult(Either<Failure, void> result) => _result = result;

  @override
  Future<Either<Failure, void>> addToFavorites(int propertyId) async => _result;

  @override
  Future<Either<Failure, void>> removeFromFavorites(int propertyId) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<PropertyEntity>>> getUserFavorites() async => throw UnimplementedError();
}

void main() {
  late AddToFavoriteUseCase useCase;
  late MockFavoriteRepository repository;

  setUp(() {
    repository = MockFavoriteRepository();
    useCase = AddToFavoriteUseCase(repository);
  });

  test('should successfully add property to favorites', () async {
    final result = await useCase(1);

    expect(result.isRight(), true);
  });

  test('should return failure on error', () async {
    repository.setResult(const Left(ServerFailure('Failed to add')));

    final result = await useCase(1);

    expect(result.isLeft(), true);
    result.fold((failure) {
      expect(failure.message, 'Failed to add');
    }, (_) {});
  });

  test('should return UnauthorizedFailure when unauthorized', () async {
    repository.setResult(const Left(UnauthorizedFailure()));

    final result = await useCase(1);

    expect(result.isLeft(), true);
    result.fold((failure) {
      expect(failure, isA<UnauthorizedFailure>());
    }, (_) {});
  });
}
