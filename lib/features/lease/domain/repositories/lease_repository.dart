import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/lease_entity.dart';

abstract class LeaseRepository {
  Future<Either<Failure, List<LeaseEntity>>> getLeasesAsRenter();
  Future<Either<Failure, List<LeaseEntity>>> getLeasesAsOwner();
  Future<Either<Failure, LeaseEntity>> getLeaseById(String leaseId);
}
