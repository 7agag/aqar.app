import 'package:dio/dio.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/features/review/domain/entities/review_entity.dart';

abstract class ReviewRemoteDataSource {
  Future<List<ReviewEntity>> getReviews({int? propertyId});
  Future<void> addReview({
    required double rating,
    required String phrase,
    int? propertyId,
    String? rentId,
    String? leaseId,
  });
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final ApiClient apiClient;
  ReviewRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<ReviewEntity>> getReviews({int? propertyId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (propertyId != null) queryParams['property_id'] = propertyId;
      final response = await apiClient.dio.get(
        '/Reviews',
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) =>
                ReviewEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const ServerException('Unexpected response format');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['msg'] as String?;
      throw ServerException(msg ?? e.message ?? 'Something went wrong');
    }
  }

  @override
  Future<void> addReview({
    required double rating,
    required String phrase,
    int? propertyId,
    String? rentId,
    String? leaseId,
  }) async {
    try {
      final body = <String, dynamic>{
        'rating': rating,
        'phrase': phrase,
      };
      if (propertyId != null) body['property_id'] = propertyId;
      if (rentId != null) body['rent_id'] = rentId;
      if (leaseId != null) body['lease_id'] = leaseId;
      await apiClient.dio.post('/review', data: body);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['msg'] as String?;
      throw ServerException(msg ?? e.message ?? 'Something went wrong');
    }
  }
}
