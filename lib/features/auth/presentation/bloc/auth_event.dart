// lib/features/auth/presentation/bloc/auth_event.dart


import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String firstName;
  final String secondName;
  final String email;
  final String password;
  final String confirmPassword;
  const RegisterRequested({
    required this.firstName,
    required this.secondName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });
  @override
  List<Object?> get props => [firstName, secondName, email, password, confirmPassword];
}

class LogoutRequested extends AuthEvent {}

class VerifyOtpRequested extends AuthEvent {
  final String email;
  final String otp;
  const VerifyOtpRequested({required this.email, required this.otp});
  @override
  List<Object?> get props => [email, otp];
}

class OtpRequested extends AuthEvent {
  final String email;
  const OtpRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  const ForgotPasswordRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;
  const ResetPasswordRequested({required this.token, required this.newPassword});
  @override
  List<Object?> get props => [token, newPassword];
}

class GetProfileRequested extends AuthEvent {}

class VerifyResetTokenRequested extends AuthEvent {
  final String token;
  const VerifyResetTokenRequested({required this.token});
  @override
  List<Object?> get props => [token];
}

class CheckAuthStatus extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final String? firstName;
  final String? secondName;
  final String? email;
  const UpdateProfileRequested({this.firstName, this.secondName, this.email});
  @override
  List<Object?> get props => [firstName, secondName, email];
}

class ChangePasswordRequested extends AuthEvent {
  final String email;
  final String currentPassword;
  final String newPassword;
  const ChangePasswordRequested({
    required this.email,
    required this.currentPassword,
    required this.newPassword,
  });
  @override
  List<Object?> get props => [email, currentPassword, newPassword];
}