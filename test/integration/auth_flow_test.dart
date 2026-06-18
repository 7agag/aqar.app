import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dartz/dartz.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/core/theme/app_theme.dart';
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
import 'package:aqar/features/auth/presentation/pages/auth_page.dart';

class MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value != null) _store[key] = value;
  }

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => _store[key];

  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll({AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    _store.clear();
  }
}

class MockAuthRepository extends AuthRepository {
  @override
  Future<Either<Failure, String>> login({required String email, required String password}) async => const Right('token');
  @override
  Future<Either<Failure, String>> register({required String firstName, required String secondName, required String email, required String password, required String confirmPassword}) async => const Right('ok');
  @override
  Future<Either<Failure, void>> logout() async => const Right(null);
  @override
  Future<Either<Failure, void>> requestPasswordReset({required String email}) async => const Right(null);
  @override
  Future<Either<Failure, void>> resetPassword({required String token, required String newPassword}) async => const Right(null);
  @override
  Future<Either<Failure, void>> requestOtp({required String email}) async => const Right(null);
  @override
  Future<Either<Failure, void>> verifyOtp({required String email, required String otp}) async => const Right(null);
  @override
  Future<Either<Failure, UserEntity>> getProfile() async => Right(const UserEntity(id: '1', firstName: 'T', secondName: 'U', email: 'e@e.com'));
}

AuthBloc createTestAuthBloc() {
  final repo = MockAuthRepository();
  return AuthBloc(
    loginUseCase: LoginUseCase(repo),
    registerUseCase: RegisterUseCase(repo),
    logoutUseCase: LogoutUseCase(repo),
    forgotPasswordUseCase: ForgotPasswordUseCase(repo),
    resetPasswordUseCase: ResetPasswordUseCase(repo),
    verifyOtpUseCase: VerifyOtpUseCase(repo),
    requestOtpUseCase: RequestOtpUseCase(repo),
    getProfileUseCase: GetProfileUseCase(repo),
    secureStorage: MockSecureStorage(),
  );
}

void main() {
  testWidgets('AuthPage shows login form by default with Sign In button', (tester) async {
    final authBloc = createTestAuthBloc();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const AuthPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsWidgets);
  });

  testWidgets('AuthPage toggles to register form when Register tab is tapped', (tester) async {
    final authBloc = createTestAuthBloc();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const AuthPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
  });
}
