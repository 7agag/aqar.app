import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/purchase_request/domain/entities/purchase_request_entity.dart';
import 'package:aqar/features/purchase_request/domain/repositories/purchase_request_repository.dart';

@injectable
class GetReceivedPurchaseRequestsUseCase
    extends UseCase<List<PurchaseRequestEntity>, NoParams> {
  final PurchaseRequestRepository repository;
  GetReceivedPurchaseRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PurchaseRequestEntity>>> call(
      NoParams params) {
    return repository.getReceivedRequests();
  }
}
