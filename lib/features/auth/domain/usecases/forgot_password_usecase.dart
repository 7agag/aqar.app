import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class ForgotPasswordUseCase extends UseCase<void, ForgotPasswordParams> {
  final AuthRepository repository;
  ForgotPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ForgotPasswordParams params) {
    return repository.requestPasswordReset(email: params.email);
  }
}

class ForgotPasswordParams extends Equatable {
  final String email;
  const ForgotPasswordParams({required this.email});

  @override
  List<Object> get props => [email];
}