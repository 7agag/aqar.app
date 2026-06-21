import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_filter_params.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/property_remote_datasource.dart';

@Injectable(as: PropertyRepository)
class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyRemoteDataSource remoteDataSource;
  PropertyRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<PropertyEntity>>> getProperties(
    PropertyFilterParams params,
  ) async {
    try {
      final result = await remoteDataSource.getProperties(params);
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, PropertyEntity>> getPropertyById(int id) async {
    try {
      final result = await remoteDataSource.getPropertyById(id);
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<PropertyEntity>>> getMyProperties() async {
    try {
      final result = await remoteDataSource.getMyProperties();
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addProperty(FormData formData) async {
    try {
      await remoteDataSource.addProperty(formData);
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> editProperty(int id, Map<String, dynamic> data) async {
    try {
      await remoteDataSource.editProperty(id, data);
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> editPropertyImages(int id, FormData formData) async {
    try {
      await remoteDataSource.editPropertyImages(id, formData);
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProperty(int id) async {
    try {
      await remoteDataSource.deleteProperty(id);
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getBookedDates(int id) async {
    try {
      final result = await remoteDataSource.getBookedDates(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}