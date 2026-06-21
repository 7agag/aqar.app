import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/purchase_request/domain/repositories/purchase_request_repository.dart';

@injectable
class UpdatePurchaseRequestStatusUseCase
    extends UseCase<String, UpdatePurchaseRequestStatusParams> {
  final PurchaseRequestRepository repository;
  UpdatePurchaseRequestStatusUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(
      UpdatePurchaseRequestStatusParams params) {
    return repository.updateRequestStatus(
      requestId: params.requestId,
      status: params.status,
    );
  }
}

class UpdatePurchaseRequestStatusParams {
  final String requestId;
  final String status;
  const UpdatePurchaseRequestStatusParams({
    required this.requestId,
    required this.status,
  });
}
