import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/payment_repository.dart';

@injectable
class RequestWithdrawalUseCase
    extends UseCase<({String msg, String? transferId}), RequestWithdrawalParams> {
  final PaymentRepository repository;
  RequestWithdrawalUseCase(this.repository);

  @override
  Future<Either<Failure, ({String msg, String? transferId})>> call(
      RequestWithdrawalParams params) {
    return repository.requestWithdrawal(
      amount: params.amount,
      method: params.method,
      receiverData: params.receiverData,
    );
  }
}

class RequestWithdrawalParams {
  final double amount;
  final String method;
  final String receiverData;
  const RequestWithdrawalParams({
    required this.amount,
    required this.method,
    required this.receiverData,
  });
}
