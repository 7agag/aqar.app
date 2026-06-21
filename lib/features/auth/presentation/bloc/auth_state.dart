// lib/features/auth/presentation/bloc/auth_state.dart


import 'package:aqar/features/auth/domain/entities/user_entity.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthLoginSuccess extends AuthState {
  final String token;
  const AuthLoginSuccess(this.token);
  @override
  List<Object?> get props => [token];
}

class AuthRegisterSuccess extends AuthState {
  final String email;
  const AuthRegisterSuccess(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthUnauthenticated extends AuthState {}

class AuthOtpVerified extends AuthState {}

class AuthOtpSent extends AuthState {}

class AuthPasswordResetSent extends AuthState {}

class AuthPasswordResetSuccess extends AuthState {}

class AuthResetTokenVerified extends AuthState {}

class AuthResetTokenInvalid extends AuthState {
  final String message;
  const AuthResetTokenInvalid(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthProfileLoading extends AuthState {}

class AuthProfileLoaded extends AuthState {
  final UserEntity user;
  const AuthProfileLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthProfileUpdateSuccess extends AuthState {
  final UserEntity user;
  const AuthProfileUpdateSuccess(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthPasswordChangeSuccess extends AuthState {}