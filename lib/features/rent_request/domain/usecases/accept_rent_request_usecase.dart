import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import '../repositories/rent_request_repository.dart';

@injectable
class AcceptRentRequestUseCase implements UseCase<void, String> {
  final RentRequestRepository repository;

  AcceptRentRequestUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String requestId) {
    return repository.acceptRequest(requestId);
  }
}
