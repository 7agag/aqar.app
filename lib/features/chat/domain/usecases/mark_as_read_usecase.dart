import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

@injectable
class MarkAsReadUseCase extends UseCase<void, String> {
  final ChatRepository repository;
  MarkAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return repository.markAsRead(params);
  }
}
