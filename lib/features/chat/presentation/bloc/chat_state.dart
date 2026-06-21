import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';

abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class InboxLoaded extends ChatState {
  final List<ChatThreadEntity> threads;
  InboxLoaded({required this.threads});
  @override
  List<Object?> get props => [threads];
}

class ChatHistoryLoaded extends ChatState {
  final String chatId;
  final List<ChatMessageEntity> messages;
  final String? partnerId;
  final int? propertyId;
  ChatHistoryLoaded({
    required this.chatId,
    required this.messages,
    this.partnerId,
    this.propertyId,
  });
  @override
  List<Object?> get props => [chatId, messages, partnerId, propertyId];
}

class MessageSent extends ChatState {
  final Map<String, dynamic> data;
  MessageSent(this.data);
  @override
  List<Object?> get props => [data];
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
  @override
  List<Object?> get props => [message];
}
