import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/entities/balance_entity.dart';
import '../../domain/entities/payment_entity.dart';

abstract class PaymentRemoteDataSource {
  Future<BalanceEntity> getBalance();
  Future<List<TransactionEntity>> getTransactions();
  Future<PaymentLinkEntity> getPaymentLink({
    String? requestId,
    String? invoiceId,
    String? subscriptionId,
    String? redirect,
  });
  Future<({String msg, String? transferId})> requestWithdrawal({
    required double amount,
    required String method,
    required String receiverData,
  });
  Future<String> requestRefund({
    required String requestId,
    String? reason,
  });
  Future<String> cancelRefundRequest(String requestId);
  Future<TransferStatusEntity> getTransferStatus(String transferId);
}

@Injectable(as: PaymentRemoteDataSource)
class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient apiClient;
  PaymentRemoteDataSourceImpl(this.apiClient);

  @override
  Future<BalanceEntity> getBalance() async {
    try {
      final response = await apiClient.dio.get('/api/balance');
      final data = response.data as Map<String, dynamic>;
      return BalanceEntity.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['msg'] ?? 'Failed to fetch balance',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    try {
      final response = await apiClient.dio.get('/api/payment/transactions');
      final data = response.data as Map<String, dynamic>;
      final rawList = data['transactions'] as List?;
      if (rawList == null) return const [];
      return rawList
          .cast<Map<String, dynamic>>()
          .map((e) => TransactionEntity.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['msg'] ?? 'Failed to fetch transactions',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<PaymentLinkEntity> getPaymentLink({
    String? requestId,
    String? invoiceId,
    String? subscriptionId,
    String? redirect,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (requestId != null) body['request_id'] = requestId;
      if (invoiceId != null) body['invoice_id'] = invoiceId;
      if (subscriptionId != null) body['subscription_id'] = subscriptionId;
      if (redirect != null) body['redirect'] = redirect;
      final response = await apiClient.dio.post('/api/payment/', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['url'] != null) return PaymentLinkEntity.fromJson(data);
      throw ServerException(
        data['msg'] as String? ?? 'Failed to generate payment link',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['msg'] as String? ?? 'Failed to generate payment link',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<({String msg, String? transferId})> requestWithdrawal({
    required double amount,
    required String method,
    required String receiverData,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/api/payment/request-withdrawal',
        data: {
          'amount': amount,
          'method': method,
          'receiverData': receiverData,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (
        msg: data['msg'] as String? ?? 'Withdrawal requested',
        transferId: data['transferId'] as String?,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['msg'] as String? ?? 'Failed to request withdrawal',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<String> requestRefund({
    required String requestId,
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{'request_id': requestId};
      if (reason != null) body['reason'] = reason;
      final response =
          await apiClient.dio.post('/api/payment/request-refund', data: body);
      final data = response.data as Map<String, dynamic>;
      return data['msg'] as String? ?? 'Refund requested';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['msg'] as String? ?? 'Failed to request refund',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<String> cancelRefundRequest(String requestId) async {
    try {
      final response = await apiClient.dio.post(
        '/api/payment/cancel-refund-request',
        data: {'request_id': requestId},
      );
      final data = response.data as Map<String, dynamic>;
      return data['msg'] as String? ?? 'Refund request cancelled';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['msg'] as String? ?? 'Failed to cancel refund request',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<TransferStatusEntity> getTransferStatus(String transferId) async {
    try {
      final response =
          await apiClient.dio.get('/api/payment/transfer-status/$transferId');
      final data = response.data as Map<String, dynamic>;
      return TransferStatusEntity.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['msg'] as String? ?? 'Failed to get transfer status',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
