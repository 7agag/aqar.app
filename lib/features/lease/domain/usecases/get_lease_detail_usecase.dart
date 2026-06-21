import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/lease_entity.dart';
import '../repositories/lease_repository.dart';

@injectable
class GetLeaseDetailUseCase
    extends UseCase<LeaseEntity, GetLeaseDetailParams> {
  final LeaseRepository repository;
  GetLeaseDetailUseCase(this.repository);

  @override
  Future<Either<Failure, LeaseEntity>> call(GetLeaseDetailParams params) {
    return repository.getLeaseById(params.leaseId);
  }
}

class GetLeaseDetailParams {
  final String leaseId;
  const GetLeaseDetailParams({required this.leaseId});
}
