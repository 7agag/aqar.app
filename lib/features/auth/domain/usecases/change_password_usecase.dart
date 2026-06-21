import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class ChangePasswordUseCase extends UseCase<void, ChangePasswordParams> {
  final AuthRepository repository;
  ChangePasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ChangePasswordParams params) {
    return repository.changePassword(
      email: params.email,
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }
}

class ChangePasswordParams extends Equatable {
  final String email;
  final String currentPassword;
  final String newPassword;

  const ChangePasswordParams({
    required this.email,
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, currentPassword, newPassword];
}
