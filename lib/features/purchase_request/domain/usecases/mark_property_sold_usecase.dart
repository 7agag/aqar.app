import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/purchase_request/domain/repositories/purchase_request_repository.dart';

@injectable
class MarkPropertySoldUseCase
    extends UseCase<String, MarkPropertySoldParams> {
  final PurchaseRequestRepository repository;
  MarkPropertySoldUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(MarkPropertySoldParams params) {
    return repository.markPropertySold(params.propertyId);
  }
}

class MarkPropertySoldParams {
  final int propertyId;
  const MarkPropertySoldParams({required this.propertyId});
}
