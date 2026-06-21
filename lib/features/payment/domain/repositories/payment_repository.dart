import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/balance_entity.dart';
import '../entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<Either<Failure, BalanceEntity>> getBalance();
  Future<Either<Failure, List<TransactionEntity>>> getTransactions();
  Future<Either<Failure, PaymentLinkEntity>> getPaymentLink({
    String? requestId,
    String? invoiceId,
    String? subscriptionId,
    String? redirect,
  });
  Future<Either<Failure, ({String msg, String? transferId})>> requestWithdrawal({
    required double amount,
    required String method,
    required String receiverData,
  });
  Future<Either<Failure, String>> requestRefund({
    required String requestId,
    String? reason,
  });
  Future<Either<Failure, String>> cancelRefundRequest(String requestId);
  Future<Either<Failure, TransferStatusEntity>> getTransferStatus(
      String transferId);
}
