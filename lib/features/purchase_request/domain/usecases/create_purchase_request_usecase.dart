import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/purchase_request/domain/repositories/purchase_request_repository.dart';

@injectable
class CreatePurchaseRequestUseCase
    extends UseCase<String, CreatePurchaseRequestParams> {
  final PurchaseRequestRepository repository;
  CreatePurchaseRequestUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreatePurchaseRequestParams params) {
    return repository.createRequest(
      propertyId: params.propertyId,
      message: params.message,
    );
  }
}

class CreatePurchaseRequestParams {
  final int propertyId;
  final String? message;
  const CreatePurchaseRequestParams({
    required this.propertyId,
    this.message,
  });
}
