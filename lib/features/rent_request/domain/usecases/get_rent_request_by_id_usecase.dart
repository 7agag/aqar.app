import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/rent_request/domain/entities/rent_request_entity.dart';
import 'package:aqar/features/rent_request/domain/repositories/rent_request_repository.dart';

@injectable
class GetRentRequestByIdUseCase extends UseCase<RentRequestEntity, GetRentRequestByIdParams> {
  final RentRequestRepository repository;
  GetRentRequestByIdUseCase(this.repository);

  @override
  Future<Either<Failure, RentRequestEntity>> call(GetRentRequestByIdParams params) {
    return repository.getRequestById(params.requestId);
  }
}

class GetRentRequestByIdParams extends Equatable {
  final String requestId;
  const GetRentRequestByIdParams({required this.requestId});
  @override
  List<Object?> get props => [requestId];
}
