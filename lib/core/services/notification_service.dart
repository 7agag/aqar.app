import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  late final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    _plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> scheduleLeaseReminder({
    required String requestId,
    required int deadlineMillis,
  }) async {
    if (!_initialized) return;

    final now = DateTime.now();
    final deadline = DateTime.fromMillisecondsSinceEpoch(deadlineMillis);
    final remindAt = deadline.subtract(const Duration(hours: 6));

    if (remindAt.isBefore(now) || remindAt.isAtSameMomentAs(now)) {
      await _showImmediateNotification(requestId);
      return;
    }

    final tzDeadline = tz.TZDateTime.from(deadline, tz.local);
    final tzRemindAt = tzDeadline.subtract(const Duration(hours: 6));

    await _plugin.zonedSchedule(
      requestId.hashCode,
      'Lease expiring soon',
      'Your 3-day escrow period ends soon. Confirm receipt to release payment.',
      tzRemindAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lease_reminders',
          'Lease Reminders',
          channelDescription: 'Reminders for lease deadlines',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _showImmediateNotification(String requestId) async {
    await _plugin.show(
      requestId.hashCode,
      'Lease expiring soon',
      'Your 3-day escrow period is ending. Confirm receipt now.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lease_reminders',
          'Lease Reminders',
          channelDescription: 'Reminders for lease deadlines',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
