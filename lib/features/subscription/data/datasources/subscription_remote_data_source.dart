import 'package:dio/dio.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/features/subscription/domain/entities/subscription_entity.dart';

abstract class SubscriptionRemoteDataSource {
  Future<SubscriptionEntity> getSubscription(int propertyId);
  Future<SubscriptionEntity> createSubscription({
    required int propertyId,
    required int planMonths,
  });
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final ApiClient apiClient;
  SubscriptionRemoteDataSourceImpl(this.apiClient);

  @override
  Future<SubscriptionEntity> getSubscription(int propertyId) async {
    try {
      final response =
          await apiClient.dio.get('/subscription/$propertyId');
      return SubscriptionEntity.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['msg'] as String?;
      throw ServerException(msg ?? e.message ?? 'Something went wrong');
    }
  }

  @override
  Future<SubscriptionEntity> createSubscription({
    required int propertyId,
    required int planMonths,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/subscription/$propertyId',
        data: {'planMonths': planMonths},
      );
      return SubscriptionEntity.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['msg'] as String?;
      throw ServerException(msg ?? e.message ?? 'Something went wrong');
    }
  }
}
