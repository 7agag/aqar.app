import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/chat_message_entity.dart';
import '../repositories/chat_repository.dart';

@injectable
class GetChatHistoryUseCase extends UseCase<List<ChatMessageEntity>, String> {
  final ChatRepository repository;
  GetChatHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> call(String params) {
    return repository.getChatHistory(params);
  }
}
