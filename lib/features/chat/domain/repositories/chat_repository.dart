import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/chat_message_entity.dart';
import '../entities/chat_thread_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatThreadEntity>>> getInbox();
  Future<Either<Failure, List<ChatMessageEntity>>> getChatHistory(String chatId);
  Future<Either<Failure, Map<String, dynamic>>> sendMessage({
    required String receiverId,
    required int propertyId,
    required String content,
  });
  Future<Either<Failure, void>> markAsRead(String chatId);
}
