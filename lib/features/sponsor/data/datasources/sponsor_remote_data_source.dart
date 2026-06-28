import 'package:dio/dio.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/features/sponsor/domain/entities/sponsor_entity.dart';

abstract class SponsorRemoteDataSource {
  Future<SponsorEntity> createCheckout({
    required int propertyId,
    required int duration,
    required String redirect,
  });
}

class SponsorRemoteDataSourceImpl implements SponsorRemoteDataSource {
  final ApiClient apiClient;
  SponsorRemoteDataSourceImpl(this.apiClient);

  @override
  Future<SponsorEntity> createCheckout({
    required int propertyId,
    required int duration,
    required String redirect,
  }) async {
    const maxRetries = 2;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await apiClient.dio.post(
          '/api/sponser',
          data: {
            'property_id': propertyId,
            'duration': duration,
            'redirect': redirect,
          },
          options: Options(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        );
        return SponsorEntity.fromJson(response.data as Map<String, dynamic>);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) throw UnauthorizedException();
        final isLast = attempt == maxRetries - 1;
        if (!isLast &&
            (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.connectionError)) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        final msg =
            (e.response?.data as Map<String, dynamic>?)?['message'] as String?;
        throw ServerException(msg ?? e.message ?? 'Payment service unavailable');
      }
    }
    throw ServerException('Failed to reach payment service');
  }
}
