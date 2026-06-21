import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

@injectable
class MarkNotificationReadUseCase
    extends UseCase<void, MarkNotificationReadParams> {
  final NotificationRepository repository;
  MarkNotificationReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkNotificationReadParams params) {
    return repository.markAsRead(params.notificationId);
  }
}

class MarkNotificationReadParams {
  final String notificationId;
  const MarkNotificationReadParams({required this.notificationId});
}
