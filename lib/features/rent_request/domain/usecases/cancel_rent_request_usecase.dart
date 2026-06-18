import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import '../repositories/rent_request_repository.dart';

@injectable
class CancelRentRequestUseCase implements UseCase<void, String> {
  final RentRequestRepository repository;

  CancelRentRequestUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String requestId) {
    return repository.cancelRequest(requestId);
  }
}
