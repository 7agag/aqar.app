import 'package:equatable/equatable.dart';
import '../../../ai/domain/entities/ai_message_entity.dart';

abstract class AiState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AiInitial extends AiState {}

class AiLoaded extends AiState {
  final List<AiMessageEntity> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool notifyUnread;

  AiLoaded({
    required this.messages,
    this.isLoading = false,
    this.errorMessage,
    this.notifyUnread = false,
  });

  @override
  List<Object?> get props => [messages, isLoading, errorMessage, notifyUnread];
}

class AiError extends AiState {
  final String message;
  AiError(this.message);
  @override
  List<Object?> get props => [message];
}
