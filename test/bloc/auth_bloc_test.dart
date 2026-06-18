import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/auth/domain/entities/user_entity.dart';
import 'package:aqar/features/auth/domain/repositories/auth_repository.dart';
import 'package:aqar/features/auth/domain/usecases/login_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/register_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/logout_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/request_otp_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_event.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepo extends AuthRepository {
  @override
  Future<Either<Failure, String>> login({required String email, required String password}) async => const Right('token');
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

class MockLoginUseCase extends LoginUseCase {
  MockLoginUseCase() : super(MockAuthRepo());
  Either<Failure, String> result = const Right('token123');
  @override
  Future<Either<Failure, String>> call(LoginParams params) async => result;
}

class MockRegisterUseCase extends RegisterUseCase {
  MockRegisterUseCase() : super(MockAuthRepo());
  @override
  Future<Either<Failure, String>> call(RegisterParams params) async => const Right('Registered');
}

class MockLogoutUseCase extends LogoutUseCase {
  MockLogoutUseCase() : super(MockAuthRepo());
  @override
  Future<Either<Failure, void>> call(NoParams params) async => const Right(null);
}

class MockForgotPasswordUseCase extends ForgotPasswordUseCase {
  MockForgotPasswordUseCase() : super(MockAuthRepo());
  @override
  Future<Either<Failure, void>> call(ForgotPasswordParams params) async => const Right(null);
}

class MockResetPasswordUseCase extends ResetPasswordUseCase {
  MockResetPasswordUseCase() : super(MockAuthRepo());
  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async => const Right(null);
}

class MockVerifyOtpUseCase extends VerifyOtpUseCase {
  MockVerifyOtpUseCase() : super(MockAuthRepo());
  @override
  Future<Either<Failure, void>> call(VerifyOtpParams params) async => const Right(null);
}

class MockRequestOtpUseCase extends RequestOtpUseCase {
  MockRequestOtpUseCase() : super(MockAuthRepo());
  @override
  Future<Either<Failure, void>> call(RequestOtpParams params) async => const Right(null);
}

class MockGetProfileUseCase extends GetProfileUseCase {
  MockGetProfileUseCase() : super(MockAuthRepo());
  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async => Right(const UserEntity(id: '1', firstName: 'Test', secondName: 'User', email: 'test@test.com'));
}

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    authBloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      registerUseCase: MockRegisterUseCase(),
      logoutUseCase: MockLogoutUseCase(),
      forgotPasswordUseCase: MockForgotPasswordUseCase(),
      resetPasswordUseCase: MockResetPasswordUseCase(),
      verifyOtpUseCase: MockVerifyOtpUseCase(),
      requestOtpUseCase: MockRequestOtpUseCase(),
      getProfileUseCase: MockGetProfileUseCase(),
      secureStorage: const FlutterSecureStorage(),
    );
  });

  tearDown(() {
    authBloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthLoginSuccess] when login is successful',
    build: () => authBloc,
    act: (bloc) => bloc.add(const LoginRequested(email: 'test@test.com', password: 'password')),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthLoginSuccess>(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthError] when login fails',
    build: () {
      mockLoginUseCase.result = const Left(ServerFailure('Invalid credentials'));
      return authBloc;
    },
    act: (bloc) => bloc.add(const LoginRequested(email: 'test@test.com', password: 'wrong')),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthUnauthenticated] on logout',
    build: () => authBloc,
    act: (bloc) => bloc.add(LogoutRequested()),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthUnauthenticated>(),
    ],
  );
}
