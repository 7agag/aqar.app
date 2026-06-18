import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/favorite/data/datasources/favorite_remote_data_source.dart';
import 'package:aqar/features/favorite/data/repositories/favorite_repository_impl.dart';
import 'package:aqar/features/property/data/models/property_model.dart';

class MockFavoriteDataSource extends FavoriteRemoteDataSource {
  ServerException? addError;
  ServerException? removeError;

  @override
  Future<void> addToFavorites(int propertyId) async {
    if (addError != null) throw addError!;
  }

  @override
  Future<void> removeFromFavorites(int propertyId) async {
    if (removeError != null) throw removeError!;
  }

  @override
  Future<List<PropertyModel>> getUserFavorites() async => [];
}

void main() {
  late FavoriteRepositoryImpl repository;
  late MockFavoriteDataSource dataSource;

  setUp(() {
    dataSource = MockFavoriteDataSource();
    repository = FavoriteRepositoryImpl(dataSource);
  });

  group('addToFavorites', () {
    test('should complete successfully', () async {
      final result = await repository.addToFavorites(1);
      expect(result.isRight(), true);
    });

    test('should return ServerFailure on error', () async {
      dataSource.addError = ServerException('Failed', statusCode: 500);

      final result = await repository.addToFavorites(1);

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
      }, (_) {});
    });
  });

  group('removeFromFavorites', () {
    test('should complete successfully', () async {
      final result = await repository.removeFromFavorites(1);
      expect(result.isRight(), true);
    });

    test('should return ServerFailure on error', () async {
      dataSource.removeError = ServerException('Failed', statusCode: 500);

      final result = await repository.removeFromFavorites(1);

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
      }, (_) {});
    });
  });
}
