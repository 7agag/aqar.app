import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/chat_thread_entity.dart';
import '../repositories/chat_repository.dart';

@injectable
class GetInboxUseCase extends UseCase<List<ChatThreadEntity>, NoParams> {
  final ChatRepository repository;
  GetInboxUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatThreadEntity>>> call(NoParams params) {
    return repository.getInbox();
  }
}
