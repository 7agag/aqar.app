import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/rent_request/domain/entities/rent_request_entity.dart';
import 'package:aqar/features/rent_request/domain/repositories/rent_request_repository.dart';
import 'package:aqar/features/rent_request/data/datasources/rent_request_remote_datasource.dart';

@Injectable(as: RentRequestRepository)
class RentRequestRepositoryImpl implements RentRequestRepository {
  final RentRequestRemoteDataSource remoteDataSource;
  RentRequestRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<RentRequestEntity>>> getSentRequests() async {
    try {
      final result = await remoteDataSource.getRequests();
      return Right(result.sent);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<RentRequestEntity>>> getReceivedRequests() async {
    try {
      final result = await remoteDataSource.getRequests();
      return Right(result.received);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> createRequest({
    required int propertyId,
    required String checkInDate,
    required String checkOutDate,
    required String rentingType,
  }) async {
    try {
      final result = await remoteDataSource.createRequest(
        propertyId: propertyId,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        rentingType: rentingType,
      );
      final id = result['request_id'];
      if (id is! String) return const Left(ServerFailure('No request_id in response'));
      return Right(id);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> acceptRequest(String requestId) async {
    try {
      await remoteDataSource.acceptRequest(requestId);
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> rejectRequest(String requestId) async {
    try {
      await remoteDataSource.rejectRequest(requestId);
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> cancelRequest(String requestId) async {
    try {
      await remoteDataSource.cancelRequest(requestId);
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
