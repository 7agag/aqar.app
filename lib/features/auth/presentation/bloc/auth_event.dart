import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String firstName;
  final String secondName;
  final String email;
  final String password;
  final String confirmPassword;

  RegisterRequested({
    required this.firstName,
    required this.secondName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object> get props => [email];
}

class LogoutRequested extends AuthEvent {}

class VerifyOtpRequested extends AuthEvent {
  final String email;
  final String otp;

  VerifyOtpRequested({required this.email, required this.otp});

  @override
  List<Object> get props => [email, otp];
}

class OtpRequested extends AuthEvent {
  final String email;

  OtpRequested({required this.email});

  @override
  List<Object> get props => [email];
}