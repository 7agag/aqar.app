import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../domain/usecases/get_inbox_usecase.dart';
import '../../domain/usecases/get_chat_history_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../../../../core/usecases/usecase.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetInboxUseCase getInbox;
  final GetChatHistoryUseCase getChatHistory;
  final SendMessageUseCase sendMessage;
  final MarkAsReadUseCase markAsRead;

  ChatBloc({
    required this.getInbox,
    required this.getChatHistory,
    required this.sendMessage,
    required this.markAsRead,
  }) : super(ChatInitial()) {

    on<GetInboxRequested>((event, emit) async {
      emit(ChatLoading());
      try {
        final result = await getInbox(NoParams());
        result.fold(
          (failure) => emit(ChatError(failure.message)),
          (threads) => emit(InboxLoaded(threads: threads)),
        );
      } catch (e) {
        emit(ChatError('Unexpected error: $e'));
      }
    });

    on<GetChatHistoryRequested>((event, emit) async {
      emit(ChatLoading());
      try {
        final result = await getChatHistory(event.chatId);
        result.fold(
          (failure) => emit(ChatError(failure.message)),
          (messages) => emit(ChatHistoryLoaded(chatId: event.chatId, messages: messages)),
        );
      } catch (e) {
        emit(ChatError('Unexpected error: $e'));
      }
    });

    on<SendMessageRequested>((event, emit) async {
      final result = await sendMessage(SendMessageParams(
        receiverId: event.receiverId,
        propertyId: event.propertyId,
        content: event.content,
      ));
      result.fold(
        (failure) => emit(ChatError(failure.message)),
        (data) => emit(MessageSent(data)),
      );
    });

    on<MarkAsReadRequested>((event, emit) async {
      final result = await markAsRead(event.chatId);
      result.fold(
        (failure) => null,
        (_) => null,
      );
    });
  }
}
