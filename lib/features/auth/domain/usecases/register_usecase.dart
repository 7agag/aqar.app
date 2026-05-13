import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class RegisterUseCase extends UseCase<String, RegisterParams> {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(RegisterParams params) {
    return repository.register(
      firstName: params.firstName,
      secondName: params.secondName,
      email: params.email,
      password: params.password,
      confirmPassword: params.confirmPassword,
    );
  }
}

class RegisterParams extends Equatable {
  final String firstName;
  final String secondName;
  final String email;
  final String password;
  final String confirmPassword;

  const RegisterParams({
    required this.firstName,
    required this.secondName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object> get props => [email];
}