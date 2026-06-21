import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/entities/invoice_entity.dart';

abstract class InvoiceRemoteDataSource {
  Future<List<InvoiceEntity>> getRenterInvoices();
  Future<List<InvoiceEntity>> getOwnerInvoices();
  Future<InvoiceStatsEntity> getInvoiceStats();
}

@Injectable(as: InvoiceRemoteDataSource)
class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final ApiClient apiClient;
  InvoiceRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<InvoiceEntity>> getRenterInvoices() async {
    try {
      final response = await apiClient.dio.get('/api/invoices/renter');
      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List?;
      if (rawList == null) return const [];
      return rawList
          .cast<Map<String, dynamic>>()
          .map((e) => InvoiceEntity.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch renter invoices',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<InvoiceEntity>> getOwnerInvoices() async {
    try {
      final response = await apiClient.dio.get('/api/invoices/owner');
      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List?;
      if (rawList == null) return const [];
      return rawList
          .cast<Map<String, dynamic>>()
          .map((e) => InvoiceEntity.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch owner invoices',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<InvoiceStatsEntity> getInvoiceStats() async {
    try {
      final response = await apiClient.dio.get('/api/invoices/stats');
      final data = response.data as Map<String, dynamic>;
      return InvoiceStatsEntity.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch invoice stats',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
