import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/entities/lease_entity.dart';
import '../../domain/repositories/lease_repository.dart';
import '../datasources/lease_remote_datasource.dart';

@Injectable(as: LeaseRepository)
class LeaseRepositoryImpl implements LeaseRepository {
  final LeaseRemoteDataSource remoteDataSource;
  LeaseRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<LeaseEntity>>> getLeasesAsRenter() async {
    try {
      final result = await remoteDataSource.getLeasesAsRenter();
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<LeaseEntity>>> getLeasesAsOwner() async {
    try {
      final result = await remoteDataSource.getLeasesAsOwner();
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, LeaseEntity>> getLeaseById(String leaseId) async {
    try {
      final result = await remoteDataSource.getLeaseById(leaseId);
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
