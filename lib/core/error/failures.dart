import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {int? statusCode});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Unauthorized access');
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('No internet connection');
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}