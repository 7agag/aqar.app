import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/auth/domain/entities/user_entity.dart';
import 'package:aqar/features/auth/domain/repositories/auth_repository.dart';
import 'package:aqar/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends AuthRepository {
  Either<Failure, String> _result = const Right('token123');

  void setResult(Either<Failure, String> result) => _result = result;

  @override
  Future<Either<Failure, String>> login({required String email, required String password}) async => _result;

  @override
  Future<Either<Failure, String>> register({required String firstName, required String secondName, required String email, required String password, required String confirmPassword}) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);

  @override
  Future<Either<Failure, void>> requestPasswordReset({required String email}) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> resetPassword({required String token, required String newPassword}) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> requestOtp({required String email}) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> verifyOtp({required String email, required String otp}) async => throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> getProfile() async => throw UnimplementedError();
}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  const params = LoginParams(email: 'test@example.com', password: 'password123');

  test('should return token on successful login', () async {
    final result = await useCase(params);

    expect(result.isRight(), true);
    result.fold((_) {}, (token) {
      expect(token, 'token123');
    });
  });

  test('should return failure on login error', () async {
    repository.setResult(const Left(ServerFailure('Invalid credentials')));

    final result = await useCase(params);

    expect(result.isLeft(), true);
    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Invalid credentials');
    }, (_) {});
  });

  test('should return UnauthorizedFailure on auth error', () async {
    repository.setResult(const Left(UnauthorizedFailure()));

    final result = await useCase(params);

    expect(result.isLeft(), true);
    result.fold((failure) {
      expect(failure, isA<UnauthorizedFailure>());
    }, (_) {});
  });
}
