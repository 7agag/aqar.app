import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/ai_response_entity.dart';

abstract class AiRemoteDataSource {
  Future<AiResponseEntity> sendChatMessage(String sessionId, String message);
  Future<List<Map<String, dynamic>>> searchProperties(String query);
  Future<List<Map<String, dynamic>>> recommendSimilarProperties({
    required String description,
    required String sessionId,
    required List<int> propertyIds,
    required int limit,
  });
}

@Injectable(as: AiRemoteDataSource)
class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  late final Dio _dio;

  AiRemoteDataSourceImpl() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.aiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  @override
  Future<AiResponseEntity> sendChatMessage(String sessionId, String message) async {
    try {
      final response = await _dio.post('/chat', data: {
        'message': message,
        'session_id': sessionId,
      });
      return AiResponseEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail']?[0]?['msg'] ??
          e.response?.data?['message'] ??
          'AI Service Error (${e.response?.statusCode ?? 'unknown'})';
      throw ServerException(msg, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchProperties(String query) async {
    try {
      final response = await _dio.post('/search', data: {
        'query': query,
      });
      final data = response.data as Map<String, dynamic>;
      return ((data['properties'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          []);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail']?[0]?['msg'] ??
          e.response?.data?['message'] ??
          'AI Search Error (${e.response?.statusCode ?? 'unknown'})';
      throw ServerException(msg, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> recommendSimilarProperties({
    required String description,
    required String sessionId,
    required List<int> propertyIds,
    required int limit,
  }) async {
    try {
      final response = await _dio.post('/recommend/similar', data: {
        'property_description': description,
        'session_id': sessionId,
        'property_ids': propertyIds,
        'limit': limit,
      });
      final data = response.data as Map<String, dynamic>;
      return ((data['properties'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          []);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail']?[0]?['msg'] ??
          e.response?.data?['message'] ??
          'AI Recommend Error (${e.response?.statusCode ?? 'unknown'})';
      throw ServerException(msg, statusCode: e.response?.statusCode);
    }
  }
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}
