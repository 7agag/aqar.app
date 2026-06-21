import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

@injectable
class SendMessageUseCase extends UseCase<Map<String, dynamic>, SendMessageParams> {
  final ChatRepository repository;
  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(SendMessageParams params) {
    return repository.sendMessage(
      receiverId: params.receiverId,
      propertyId: params.propertyId,
      content: params.content,
    );
  }
}

class SendMessageParams {
  final String receiverId;
  final int propertyId;
  final String content;
  const SendMessageParams({
    required this.receiverId,
    required this.propertyId,
    required this.content,
  });
}
