import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class VerifyResetTokenUseCase extends UseCase<void, VerifyResetTokenParams> {
  final AuthRepository repository;
  VerifyResetTokenUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(VerifyResetTokenParams params) {
    return repository.verifyResetToken(token: params.token);
  }
}

class VerifyResetTokenParams extends Equatable {
  final String token;
  const VerifyResetTokenParams({required this.token});
  @override
  List<Object?> get props => [token];
}
