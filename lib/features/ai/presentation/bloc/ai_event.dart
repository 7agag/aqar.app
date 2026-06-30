import 'package:equatable/equatable.dart';

abstract class AiEvent extends Equatable {
  const AiEvent();
  @override
  List<Object?> get props => [];
}

class SendAiMessage extends AiEvent {
  final String message;
  const SendAiMessage({required this.message});
  @override
  List<Object?> get props => [message];
}

class LoadAiChatHistory extends AiEvent {
  const LoadAiChatHistory();
}

class ResetAiChat extends AiEvent {
  const ResetAiChat();
}
