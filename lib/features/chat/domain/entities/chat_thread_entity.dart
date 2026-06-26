import 'package:equatable/equatable.dart';

class ChatThreadEntity extends Equatable {
  final String id;
  final int propertyId;
  final String propertyName;
  final String? propertyImages;
  final String partnerName;
  final String partnerId;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isPropertyDeleted;

  const ChatThreadEntity({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    this.propertyImages,
    required this.partnerName,
    required this.partnerId,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isPropertyDeleted = false,
  });

  factory ChatThreadEntity.fromJson(Map<String, dynamic> json) {
    return ChatThreadEntity(
      id: json['chat_id'] as String,
      propertyId: json['property_id'] as int,
      propertyName: json['property_name'] as String? ?? '',
      propertyImages: json['property_images'] is List
          ? (json['property_images'] as List).first?.toString()
          : json['property_images'] as String?,
      partnerName: json['partner_name'] as String? ?? '',
      partnerId: json['partner_id'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isPropertyDeleted: json['is_property_deleted'] == true || json['is_property_deleted'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'chat_id': id,
    'property_id': propertyId,
    'property_name': propertyName,
    'property_images': propertyImages,
    'partner_name': partnerName,
    'partner_id': partnerId,
    'last_message': lastMessage,
    'last_message_time': lastMessageTime?.toIso8601String(),
    'unread_count': unreadCount,
    'is_property_deleted': isPropertyDeleted,
  };

  @override
  List<Object?> get props => [id, propertyId, propertyName, partnerName, partnerId, lastMessage, lastMessageTime, unreadCount];
}
