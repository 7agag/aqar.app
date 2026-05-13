import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, String>> register({
    required String firstName,
    required String secondName,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<Either<Failure, UserEntity>> getProfile();

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> verifyOtp({
    required String email,
    required String otp,
  });

  Future<Either<Failure, void>> requestOtp({required String email});

  /// NEW: Request password reset email
  Future<Either<Failure, void>> requestPasswordReset({required String email});

  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  });
}
