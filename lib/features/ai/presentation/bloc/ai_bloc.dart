import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'ai_event.dart';
import 'ai_state.dart';
import '../../data/services/ai_chat_history_service.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/usecases/send_ai_message_usecase.dart';
import '../../data/services/ai_session_service.dart';

@injectable
class AiBloc extends Bloc<AiEvent, AiState> {
  final SendAiMessageUseCase sendAiMessage;
  final AiSessionService sessionService;
  final AiChatHistoryService historyService;
  String? _sessionId;

  AiBloc({
    required this.sendAiMessage,
    required this.sessionService,
    required this.historyService,
  }) : super(AiInitial()) {
    on<LoadAiChatHistory>(_onLoadHistory);
    on<SendAiMessage>(_onSendMessage);
    on<ResetAiChat>(_onReset);
  }

  Future<void> _ensureSession() async {
    _sessionId ??= await sessionService.getSessionId();
  }

  Future<void> _onLoadHistory(
    LoadAiChatHistory event,
    Emitter<AiState> emit,
  ) async {
    final messages = await historyService.loadMessages();
    emit(AiLoaded(messages: messages, isLoading: false));
  }

  Future<void> _onSendMessage(
      SendAiMessage event, Emitter<AiState> emit) async {
    await _ensureSession();
    final currentMessages =
        state is AiLoaded ? (state as AiLoaded).messages : <AiMessageEntity>[];

    final userMsg = AiMessageEntity(
      id: _messageId('user'),
      text: event.message,
      isUser: true,
    );
    final updatedMessages = [...currentMessages, userMsg];

    emit(AiLoaded(messages: updatedMessages, isLoading: true));
    await historyService.saveMessages(updatedMessages);

    final result = await sendAiMessage(
      SendAiMessageParams(sessionId: _sessionId!, message: event.message),
    );

    await result.fold(
      (failure) async {
        emit(
          AiLoaded(
            messages: updatedMessages,
            isLoading: false,
            errorMessage: failure.message,
          ),
        );
      },
      (response) async {
        final aiMsg = AiMessageEntity(
          id: _messageId('ai'),
          text: response.reply,
          isUser: false,
          properties:
              response.properties.isNotEmpty ? response.properties : null,
        );
        final nextMessages = [...updatedMessages, aiMsg];
        await historyService.saveMessages(nextMessages);
        emit(
          AiLoaded(
            messages: nextMessages,
            isLoading: false,
            notifyUnread: true,
          ),
        );
      },
    );
  }

  Future<void> _onReset(ResetAiChat event, Emitter<AiState> emit) async {
    _sessionId = await sessionService.resetSessionId();
    await historyService.clear();
    emit(AiLoaded(messages: [], isLoading: false));
  }

  String _messageId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}
