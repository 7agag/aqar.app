import 'package:dio/dio.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/features/purchase_request/domain/entities/purchase_request_entity.dart';

abstract class PurchaseRequestRemoteDataSource {
  Future<List<PurchaseRequestEntity>> getMyRequests();
  Future<List<PurchaseRequestEntity>> getReceivedRequests();
  Future<String> createRequest(int propertyId, String? message);
  Future<String> updateRequestStatus(String requestId, String status);
  Future<String> cancelRequest(String requestId);
  Future<String> markPropertySold(int propertyId);
}

class PurchaseRequestRemoteDataSourceImpl
    implements PurchaseRequestRemoteDataSource {
  final ApiClient apiClient;

  PurchaseRequestRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<PurchaseRequestEntity>> getMyRequests() async {
    try {
      final response = await apiClient.dio.get('/my');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => PurchaseRequestEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const ServerException('Unexpected response format');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['message'] as String?;
      throw ServerException(msg ?? e.message ?? 'Something went wrong');
    }
  }

  @override
  Future<List<PurchaseRequestEntity>> getReceivedRequests() async {
    try {
      final response = await apiClient.dio.get('/received');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => PurchaseRequestEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const ServerException('Unexpected response format');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['message'] as String?;
      throw ServerException(msg ?? e.message ?? 'Something went wrong');
    }
  }

  @override
  Future<String> createRequest(int propertyId, String? message) async {
    try {
      final response = await apiClient.dio.post('/', data: {
        'property_id': propertyId,
        if (message != null) 'message': message,
      });
      return (response.data['message'] as String?) ?? 'Request sent';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['message'] as String?;
      throw ServerException(msg ?? e.message ?? 'Something went wrong');
    }
  }

  @override
  Future<String> updateRequestStatus(
      String requestId, String status) async {
    try {
      final response =
          await apiClient.dio.put('/$requestId', data: {'status': status});
      return (response.data['message'] as String?) ?? 'Status updated';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['message'] as String?;
      throw ServerException(msg ?? e.message ?? 'Something went wrong');
    }
  }

  @override
  Future<String> cancelRequest(String requestId) async {
    try {
      final response = await apiClient.dio.put('/$requestId/cancel');
      return (response.data['message'] as String?) ?? 'Request cancelled';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['message'] as String?;
      throw ServerException(msg ?? e.message ?? 'Something went wrong');
    }
  }

  @override
  Future<String> markPropertySold(int propertyId) async {
    try {
      final response =
          await apiClient.dio.post('/property/$propertyId/sold');
      return (response.data['message'] as String?) ?? 'Marked as sold';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['message'] as String?;
      throw ServerException(msg ?? e.message ?? 'Something went wrong');
    }
  }
}
