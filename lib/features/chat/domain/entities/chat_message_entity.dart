import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  final String messageId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.messageId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return ChatMessageEntity(
      messageId: json['message_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'message_id': messageId,
    'sender_id': senderId,
    'content': content,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [messageId, senderId, content, isRead, createdAt];
}
