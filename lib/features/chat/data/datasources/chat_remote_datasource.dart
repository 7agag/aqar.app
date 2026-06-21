import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatThreadEntity>> getInbox();
  Future<List<ChatMessageEntity>> getChatHistory(String chatId);
  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required int propertyId,
    required String content,
  });
  Future<void> markAsRead(String chatId);
}

@Injectable(as: ChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;
  ChatRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<ChatThreadEntity>> getInbox() async {
    try {
      final response = await apiClient.dio.get('/chat/inbox');
      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List?;
      if (rawList == null) return [];
      return rawList.map((e) => ChatThreadEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch inbox',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<ChatMessageEntity>> getChatHistory(String chatId) async {
    try {
      final response = await apiClient.dio.get('/chat/history/$chatId');
      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List?;
      if (rawList == null) return [];
      return rawList.map((e) => ChatMessageEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch chat history',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required int propertyId,
    required String content,
  }) async {
    try {
      final response = await apiClient.dio.post('/chat/send', data: {
        'receiver_id': receiverId,
        'property_id': propertyId,
        'content': content,
      });
      final data = response.data as Map<String, dynamic>;
      return (data['data'] as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to send message',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> markAsRead(String chatId) async {
    try {
      await apiClient.dio.patch('/chat/read/$chatId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to mark as read',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
