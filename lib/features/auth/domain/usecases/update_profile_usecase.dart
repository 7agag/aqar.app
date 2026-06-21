import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@injectable
class UpdateProfileUseCase extends UseCase<UserEntity, UpdateProfileParams> {
  final AuthRepository repository;
  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) {
    return repository.updateProfile(
      firstName: params.firstName,
      secondName: params.secondName,
      email: params.email,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String? firstName;
  final String? secondName;
  final String? email;

  const UpdateProfileParams({this.firstName, this.secondName, this.email});

  @override
  List<Object?> get props => [firstName, secondName, email];
}
