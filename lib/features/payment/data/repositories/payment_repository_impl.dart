import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/entities/balance_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

@Injectable(as: PaymentRepository)
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;
  PaymentRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, BalanceEntity>> getBalance() async {
    try {
      final result = await remoteDataSource.getBalance();
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions() async {
    try {
      final result = await remoteDataSource.getTransactions();
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, PaymentLinkEntity>> getPaymentLink({
    String? requestId,
    String? invoiceId,
    String? subscriptionId,
    String? redirect,
  }) async {
    try {
      final result = await remoteDataSource.getPaymentLink(
        requestId: requestId,
        invoiceId: invoiceId,
        subscriptionId: subscriptionId,
        redirect: redirect,
      );
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ({String msg, String? transferId})>>
      requestWithdrawal({
    required double amount,
    required String method,
    required String receiverData,
  }) async {
    try {
      final result = await remoteDataSource.requestWithdrawal(
        amount: amount,
        method: method,
        receiverData: receiverData,
      );
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> requestRefund({
    required String requestId,
    String? reason,
  }) async {
    try {
      final result = await remoteDataSource.requestRefund(
        requestId: requestId,
        reason: reason,
      );
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> cancelRefundRequest(String requestId) async {
    try {
      final result = await remoteDataSource.cancelRefundRequest(requestId);
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, TransferStatusEntity>> getTransferStatus(
      String transferId) async {
    try {
      final result = await remoteDataSource.getTransferStatus(transferId);
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
