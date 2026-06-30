import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/entities/notification_entity.dart';

abstract class NotificationRemoteDataSource {
  Future<(List<NotificationEntity>, int)> getNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> updatePreferences({required bool email, required bool sms});
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
        debugPrint('[NOTIFICATIONS] Unexpected response type: ${raw.runtimeType}');
        return (const <NotificationEntity>[], 0);
      }

      final Map<String, dynamic> dataObj;
      if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
        dataObj = raw['data'] as Map<String, dynamic>;
      } else {
        dataObj = raw;
      }

      final unreadCount = dataObj['unreadCount'] as int? ?? 0;
      final rawList = dataObj['notifications'] as List?;
      if (rawList == null) {
        debugPrint('[NOTIFICATIONS] No notifications array in response: $dataObj');
        return (const <NotificationEntity>[], unreadCount);
      }

      final notifications = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => NotificationEntity.fromJson(e))
          .toList();
      debugPrint('[NOTIFICATIONS] Loaded ${notifications.length} notifications, unread: $unreadCount');
      return (notifications, unreadCount);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch notifications',
        statusCode: e.response?.statusCode,
      );
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

  @override
  Future<void> updatePreferences({required bool email, required bool sms}) async {
    try {
      await apiClient.dio.put(
        '/api/notification/preferences',
        data: {'email': email, 'sms': sms},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
    }
  }
}
