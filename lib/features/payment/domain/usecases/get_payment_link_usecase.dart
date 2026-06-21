import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

@injectable
class GetPaymentLinkUseCase
    extends UseCase<PaymentLinkEntity, GetPaymentLinkParams> {
  final PaymentRepository repository;
  GetPaymentLinkUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentLinkEntity>> call(
      GetPaymentLinkParams params) {
    return repository.getPaymentLink(
      requestId: params.requestId,
      invoiceId: params.invoiceId,
      subscriptionId: params.subscriptionId,
      redirect: params.redirect,
    );
  }
}

class GetPaymentLinkParams {
  final String? requestId;
  final String? invoiceId;
  final String? subscriptionId;
  final String? redirect;
  const GetPaymentLinkParams({
    this.requestId,
    this.invoiceId,
    this.subscriptionId,
    this.redirect,
  });
}
