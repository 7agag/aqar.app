import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/purchase_request/domain/repositories/purchase_request_repository.dart';

@injectable
class CancelPurchaseRequestUseCase
    extends UseCase<String, CancelPurchaseRequestParams> {
  final PurchaseRequestRepository repository;
  CancelPurchaseRequestUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CancelPurchaseRequestParams params) {
    return repository.cancelRequest(params.requestId);
  }
}

class CancelPurchaseRequestParams {
  final String requestId;
  const CancelPurchaseRequestParams({required this.requestId});
}
