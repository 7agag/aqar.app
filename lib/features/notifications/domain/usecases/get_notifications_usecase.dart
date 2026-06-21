import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

@injectable
class GetNotificationsUseCase
    extends UseCase<(List<NotificationEntity>, int), NoParams> {
  final NotificationRepository repository;
  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, (List<NotificationEntity>, int)>> call(
      NoParams params) {
    return repository.getNotifications();
  }
}
