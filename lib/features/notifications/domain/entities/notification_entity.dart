import 'dart:convert';
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
    String? safeString(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    }

    String? safeMetadata(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      return jsonEncode(v);
    }

    DateTime safeDateTime(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      return DateTime.now();
    }

    return NotificationEntity(
      notificationId: safeString(json['notification_id']) ?? '',
      receiver: safeString(json['receiver']) ?? '',
      type: safeString(json['event_type']) ?? '',
      title: safeString(json['notification_title']) ?? '',
      body: safeString(json['notification_body']) ?? '',
      metadata: safeMetadata(json['metadata']),
      viewed: json['viewed'] == true || json['viewed'] == 1,
      createdAt: safeDateTime(json['created_at']),
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
