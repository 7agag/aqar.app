import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../property/domain/entities/property_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../datasources/favorite_remote_data_source.dart';

@Injectable(as: FavoriteRepository)
class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteRemoteDataSource remoteDataSource;

  FavoriteRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> addToFavorites(int propertyId) async {
    try {
      await remoteDataSource.addToFavorites(propertyId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on UnauthorizedException {
      return Left(UnauthorizedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> removeFromFavorites(int propertyId) async {
    try {
      await remoteDataSource.removeFromFavorites(propertyId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on UnauthorizedException {
      return Left(UnauthorizedFailure());
    }
  }

  @override
  Future<Either<Failure, List<PropertyEntity>>> getUserFavorites() async {
    try {
      final result = await remoteDataSource.getUserFavorites();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on UnauthorizedException {
      return Left(UnauthorizedFailure());
    }
  }
}