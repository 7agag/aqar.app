import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('غير مصرح لك بالدخول');
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('تحقق من الاتصال بالإنترنت');
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}