import 'package:dartz/dartz.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/features/purchase_request/domain/entities/purchase_request_entity.dart';
import 'package:aqar/features/purchase_request/domain/repositories/purchase_request_repository.dart';
import 'package:aqar/features/purchase_request/data/datasources/purchase_request_remote_data_source.dart';

class PurchaseRequestRepositoryImpl implements PurchaseRequestRepository {
  final PurchaseRequestRemoteDataSource remoteDataSource;

  PurchaseRequestRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<PurchaseRequestEntity>>>
      getMyRequests() async {
    try {
      final result = await remoteDataSource.getMyRequests();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException {
      return Left(const UnauthorizedFailure());
    }
  }

  @override
  Future<Either<Failure, List<PurchaseRequestEntity>>>
      getReceivedRequests() async {
    try {
      final result = await remoteDataSource.getReceivedRequests();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException {
      return Left(const UnauthorizedFailure());
    }
  }

  @override
  Future<Either<Failure, String>> createRequest({
    required int propertyId,
    String? message,
  }) async {
    try {
      final result = await remoteDataSource.createRequest(propertyId, message);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException {
      return Left(const UnauthorizedFailure());
    }
  }

  @override
  Future<Either<Failure, String>> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      final result =
          await remoteDataSource.updateRequestStatus(requestId, status);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException {
      return Left(const UnauthorizedFailure());
    }
  }

  @override
  Future<Either<Failure, String>> cancelRequest(String requestId) async {
    try {
      final result = await remoteDataSource.cancelRequest(requestId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException {
      return Left(const UnauthorizedFailure());
    }
  }

  @override
  Future<Either<Failure, String>> markPropertySold(int propertyId) async {
    try {
      final result = await remoteDataSource.markPropertySold(propertyId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException {
      return Left(const UnauthorizedFailure());
    }
  }
}
