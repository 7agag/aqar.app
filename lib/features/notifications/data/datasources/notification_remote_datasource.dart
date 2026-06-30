import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/entities/notification_entity.dart';

abstract class NotificationRemoteDataSource {
  Future<(List<NotificationEntity>, int)> getNotifications();
  Future<void> markAsRead(String notificationId);
}

@Injectable(as: NotificationRemoteDataSource)
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;
  NotificationRemoteDataSourceImpl(this.apiClient);

  @override
  Future<(List<NotificationEntity>, int)> getNotifications() async {
    try {
      final response = await apiClient.dio.get('/api/notification');
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        return (const <NotificationEntity>[], 0);
      }
      final dataObj = raw['data'] as Map<String, dynamic>?;
      final unreadCount = dataObj?['unreadCount'] as int? ?? 0;
      final rawList = dataObj?['notifications'] as List?;
      if (rawList == null) return (const <NotificationEntity>[], unreadCount);
      final notifications = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => NotificationEntity.fromJson(e))
          .toList();
      return (notifications, unreadCount);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch notifications',
        statusCode: e.response?.statusCode,
      );
    } catch (_) {
      return (const <NotificationEntity>[], 0);
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await apiClient.dio.put('/api/notification/$notificationId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to mark notification as read',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
