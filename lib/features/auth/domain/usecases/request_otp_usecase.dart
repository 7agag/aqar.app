import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class RequestOtpUseCase extends UseCase<void, RequestOtpParams> {
  final AuthRepository repository;
  RequestOtpUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RequestOtpParams params) {
    return repository.requestOtp(email: params.email);
  }
}

class RequestOtpParams extends Equatable {
  final String email;
  const RequestOtpParams({required this.email});

  @override
  List<Object> get props => [email];
}