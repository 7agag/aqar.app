import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import '../repositories/rent_request_repository.dart';

class CreateRentRequestParams extends Equatable {
  final int propertyId;
  final String checkInDate;
  final String checkOutDate;
  final String rentingType;

  const CreateRentRequestParams({
    required this.propertyId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.rentingType,
  });

  @override
  List<Object?> get props => [propertyId, checkInDate, checkOutDate, rentingType];
}

@injectable
class CreateRentRequestUseCase implements UseCase<String, CreateRentRequestParams> {
  final RentRequestRepository repository;

  CreateRentRequestUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateRentRequestParams params) {
    return repository.createRequest(
      propertyId: params.propertyId,
      checkInDate: params.checkInDate,
      checkOutDate: params.checkOutDate,
      rentingType: params.rentingType,
    );
  }
}
