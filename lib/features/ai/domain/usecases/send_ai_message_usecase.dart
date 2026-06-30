import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ai_response_entity.dart';
import '../repositories/ai_repository.dart';

@injectable
class SendAiMessageUseCase extends UseCase<AiResponseEntity, SendAiMessageParams> {
  final AiRepository repository;
  SendAiMessageUseCase(this.repository);

  @override
  Future<Either<Failure, AiResponseEntity>> call(SendAiMessageParams params) {
    return repository.sendMessage(sessionId: params.sessionId, message: params.message);
  }
}

class SendAiMessageParams {
  final String sessionId;
  final String message;
  const SendAiMessageParams({required this.sessionId, required this.message});
}
