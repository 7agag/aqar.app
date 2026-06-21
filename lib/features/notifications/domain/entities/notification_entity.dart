import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String notificationId;
  final String receiver;
  final String type;
  final String title;
  final String body;
  final String? metadata;
  final bool viewed;
  final DateTime createdAt;

  const NotificationEntity({
    required this.notificationId,
    required this.receiver,
    required this.type,
    required this.title,
    required this.body,
    this.metadata,
    this.viewed = false,
    required this.createdAt,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      notificationId: json['notification_id'] as String? ?? '',
      receiver: json['receiver'] as String? ?? '',
      type: json['event_type'] as String? ?? '',
      title: json['notification_title'] as String? ?? '',
      body: json['notification_body'] as String? ?? '',
      metadata: json['metadata'] as String?,
      viewed: json['viewed'] == true || json['viewed'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'notification_id': notificationId,
    'receiver': receiver,
    'type': type,
    'title': title,
    'body': body,
    'metadata': metadata,
    'viewed': viewed,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props =>
      [notificationId, receiver, type, title, body, metadata, viewed, createdAt];
}
