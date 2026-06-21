import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

@injectable
class GetTransferStatusUseCase
    extends UseCase<TransferStatusEntity, GetTransferStatusParams> {
  final PaymentRepository repository;
  GetTransferStatusUseCase(this.repository);

  @override
  Future<Either<Failure, TransferStatusEntity>> call(
      GetTransferStatusParams params) {
    return repository.getTransferStatus(params.transferId);
  }
}

class GetTransferStatusParams {
  final String transferId;
  const GetTransferStatusParams({required this.transferId});
}
