import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/features/rent_request/data/models/rent_request_model.dart';

abstract class RentRequestRemoteDataSource {
  Future<RentRequestListModel> getRequests();
  Future<Map<String, dynamic>> createRequest({
    required int propertyId,
    required String checkInDate,
    required String checkOutDate,
    required String rentingType,
  });
  Future<void> acceptRequest(String requestId);
  Future<void> rejectRequest(String requestId);
  Future<void> cancelRequest(String requestId);
}

@Injectable(as: RentRequestRemoteDataSource)
class RentRequestRemoteDataSourceImpl implements RentRequestRemoteDataSource {
  final ApiClient apiClient;
  RentRequestRemoteDataSourceImpl(this.apiClient);

  @override
  Future<RentRequestListModel> getRequests() async {
    try {
      final response = await apiClient.dio.get('/rent-requests');
      return RentRequestListModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to fetch requests',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> createRequest({
    required int propertyId,
    required String checkInDate,
    required String checkOutDate,
    required String rentingType,
  }) async {
    try {
      final response = await apiClient.dio.post('/rent-requests', data: {
        'property_id': propertyId,
        'check_in_date': checkInDate,
        'check_out_date': checkOutDate,
        'renting_type': rentingType,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to create request',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    try {
      await apiClient.dio.post('/rent-requests/$requestId/accept');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to accept request',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> rejectRequest(String requestId) async {
    try {
      await apiClient.dio.post('/rent-requests/$requestId/reject');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to reject request',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    try {
      await apiClient.dio.post('/rent-requests/$requestId/cancel');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to cancel request',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
