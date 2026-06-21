import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class GetNotificationsRequested extends NotificationEvent {
  const GetNotificationsRequested();
}

class MarkNotificationReadRequested extends NotificationEvent {
  final String notificationId;
  const MarkNotificationReadRequested({required this.notificationId});
  @override
  List<Object?> get props => [notificationId];
}
