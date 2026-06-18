import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import '../entities/rent_request_entity.dart';
import '../repositories/rent_request_repository.dart';

@injectable
class GetSentRequestsUseCase implements UseCase<List<RentRequestEntity>, NoParams> {
  final RentRequestRepository repository;

  GetSentRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<RentRequestEntity>>> call(NoParams params) {
    return repository.getSentRequests();
  }
}
