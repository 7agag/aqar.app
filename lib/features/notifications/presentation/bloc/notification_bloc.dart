import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'notification_event.dart';
import 'notification_state.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../../../../core/usecases/usecase.dart';

@injectable
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotifications;
  final MarkNotificationReadUseCase markNotificationRead;

  NotificationBloc({
    required this.getNotifications,
    required this.markNotificationRead,
  }) : super(NotificationInitial()) {

    on<GetNotificationsRequested>((event, emit) async {
      emit(NotificationLoading());
      try {
        final result = await getNotifications(NoParams());
        result.fold(
          (failure) => emit(NotificationError(failure.message)),
          (data) {
            final (notifications, unreadCount) = data;
            emit(NotificationsLoaded(
              notifications: notifications,
              unreadCount: unreadCount,
            ));
          },
        );
      } catch (e) {
        emit(NotificationError(e.toString()));
      }
    });

    on<MarkNotificationReadRequested>((event, emit) async {
      final result =
          await markNotificationRead(MarkNotificationReadParams(
        notificationId: event.notificationId,
      ));
      result.fold(
        (failure) => null,
        (_) {
          final current = state;
          if (current is NotificationsLoaded) {
            final updated = current.notifications.map((n) {
              if (n.notificationId == event.notificationId) {
                return NotificationEntity(
                  notificationId: n.notificationId,
                  receiver: n.receiver,
                  type: n.type,
                  title: n.title,
                  body: n.body,
                  metadata: n.metadata,
                  viewed: true,
                  createdAt: n.createdAt,
                );
              }
              return n;
            }).toList();
            final newUnread =
                (current.unreadCount - 1).clamp(0, current.unreadCount);
            emit(NotificationsLoaded(
              notifications: updated,
              unreadCount: newUnread,
            ));
          }
        },
      );
    });
  }
}
