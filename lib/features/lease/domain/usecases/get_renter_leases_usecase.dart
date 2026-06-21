import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/lease_entity.dart';
import '../repositories/lease_repository.dart';

@injectable
class GetRenterLeasesUseCase
    extends UseCase<List<LeaseEntity>, NoParams> {
  final LeaseRepository repository;
  GetRenterLeasesUseCase(this.repository);

  @override
  Future<Either<Failure, List<LeaseEntity>>> call(NoParams params) {
    return repository.getLeasesAsRenter();
  }
}
