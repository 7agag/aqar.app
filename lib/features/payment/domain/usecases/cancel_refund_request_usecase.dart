import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/payment_repository.dart';

@injectable
class CancelRefundRequestUseCase
    extends UseCase<String, CancelRefundParams> {
  final PaymentRepository repository;
  CancelRefundRequestUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CancelRefundParams params) {
    return repository.cancelRefundRequest(params.requestId);
  }
}

class CancelRefundParams {
  final String requestId;
  const CancelRefundParams({required this.requestId});
}
