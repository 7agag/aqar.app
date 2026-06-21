import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class GetInboxRequested extends ChatEvent {
  const GetInboxRequested();
}

class GetChatHistoryRequested extends ChatEvent {
  final String chatId;
  const GetChatHistoryRequested({required this.chatId});
  @override
  List<Object?> get props => [chatId];
}

class SendMessageRequested extends ChatEvent {
  final String receiverId;
  final int propertyId;
  final String content;
  const SendMessageRequested({
    required this.receiverId,
    required this.propertyId,
    required this.content,
  });
  @override
  List<Object?> get props => [receiverId, propertyId, content];
}

class MarkAsReadRequested extends ChatEvent {
  final String chatId;
  const MarkAsReadRequested({required this.chatId});
  @override
  List<Object?> get props => [chatId];
}
