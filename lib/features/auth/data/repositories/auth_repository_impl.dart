import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_datasource.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage secureStorage;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl(this.remoteDataSource, this.secureStorage, this.networkInfo);

  @override
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  }) async {
    try {
      final token = await remoteDataSource.login(email: email, password: password);
      await secureStorage.write(key: 'access_token', value: token);
      return Right(token);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> register({
    required String firstName,
    required String secondName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final msg = await remoteDataSource.register(
        firstName: firstName,
        secondName: secondName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      return Right(msg);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getProfile() async {
    try {
      final user = await remoteDataSource.getProfile();
      return Right(user);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await secureStorage.delete(key: 'access_token');
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await remoteDataSource.verifyOtp(email: email, otp: otp);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> requestOtp({required String email}) async {
    try {
      await remoteDataSource.requestOtp(email: email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> requestPasswordReset({
    required String email,
  }) async {
    try {
      await remoteDataSource.requestPasswordReset(email: email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> verifyResetToken({required String token}) async {
    try {
      await remoteDataSource.verifyResetToken(token: token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.resetPassword(token: token, newPassword: newPassword);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? firstName,
    String? secondName,
    String? email,
  }) async {
    try {
      final user = await remoteDataSource.updateProfile(
        firstName: firstName,
        secondName: secondName,
        email: email,
      );
      return Right(user);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final hasInternet = await networkInfo.isConnected;
      if (!hasInternet) {
        return const Left(NetworkFailure());
      }

      await remoteDataSource.login(email: email, password: currentPassword);
      await remoteDataSource.changePassword(newPassword);
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
