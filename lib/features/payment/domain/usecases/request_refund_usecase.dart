import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/payment_repository.dart';

@injectable
class RequestRefundUseCase
    extends UseCase<String, RequestRefundParams> {
  final PaymentRepository repository;
  RequestRefundUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(RequestRefundParams params) {
    return repository.requestRefund(
      requestId: params.requestId,
      reason: params.reason,
    );
  }
}

class RequestRefundParams {
  final String requestId;
  final String? reason;
  const RequestRefundParams({
    required this.requestId,
    this.reason,
  });
}
