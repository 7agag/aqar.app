// lib/features/auth/presentation/bloc/auth_bloc.dart

import 'package:aqar/features/auth/presentation/bloc/auth_event.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/request_otp_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final RequestOtpUseCase requestOtpUseCase;
  final GetProfileUseCase getProfileUseCase;
  final FlutterSecureStorage secureStorage;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.verifyOtpUseCase,
    required this.requestOtpUseCase,
    required this.getProfileUseCase,
    required this.secureStorage,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<VerifyOtpRequested>(_onVerifyOtp);
    on<OtpRequested>(_onRequestOtp);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ResetPasswordRequested>(_onResetPassword);
    on<GetProfileRequested>(_onGetProfile);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await loginUseCase(LoginParams(email: event.email, password: event.password));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (token) => emit(AuthLoginSuccess(token)),
    );
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await registerUseCase(RegisterParams(
      firstName: event.firstName,
      secondName: event.secondName,
      email: event.email,
      password: event.password,
      confirmPassword: event.confirmPassword,
    ));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthRegisterSuccess(event.email)),
    );
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await logoutUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onVerifyOtp(VerifyOtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await verifyOtpUseCase(VerifyOtpParams(email: event.email, otp: event.otp));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthOtpVerified()),
    );
  }

  Future<void> _onRequestOtp(OtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await requestOtpUseCase(RequestOtpParams(email: event.email));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthOtpSent()),
    );
  }

  Future<void> _onForgotPassword(ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await forgotPasswordUseCase(ForgotPasswordParams(email: event.email));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthPasswordResetSent()),
    );
  }

  Future<void> _onResetPassword(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await resetPasswordUseCase(ResetPasswordParams(token: event.token, newPassword: event.newPassword));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthPasswordResetSuccess()),
    );
  }

  Future<void> _onGetProfile(GetProfileRequested event, Emitter<AuthState> emit) async {
    emit(AuthProfileLoading());
    final result = await getProfileUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthProfileLoaded(user)),
    );
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    final token = await secureStorage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      emit(AuthLoginSuccess(token));
    } else {
      emit(AuthUnauthenticated());
    }
  }
}