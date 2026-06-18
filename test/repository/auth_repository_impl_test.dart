import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aqar/core/error/exceptions.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:aqar/features/auth/data/models/user_model.dart';
import 'package:aqar/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:aqar/features/auth/domain/entities/user_entity.dart';

class MockAuthRemoteDataSource extends AuthRemoteDataSource {
  dynamic loginError;
  String? loginResult;

  @override
  Future<String> login({required String email, required String password}) async {
    if (loginError is ServerException) throw loginError as ServerException;
    if (loginError is UnauthorizedException) throw loginError as UnauthorizedException;
    return loginResult ?? 'token';
  }

  @override
  Future<String> register({required String firstName, required String secondName, required String email, required String password, required String confirmPassword}) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<void> verifyOtp({required String email, required String otp}) async => throw UnimplementedError();

  @override
  Future<void> requestOtp({required String email}) async => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) async => throw UnimplementedError();

  @override
  Future<void> resetPassword({required String token, required String newPassword}) async => throw UnimplementedError();

  @override
  Future<UserModel> getProfile() async => throw UnimplementedError();
}

class FakeFlutterSecureStorage extends FlutterSecureStorage {
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

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource dataSource;

  setUp(() {
    dataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(dataSource, FakeFlutterSecureStorage());
  });

  group('login', () {
    test('should return token on successful login', () async {
      dataSource.loginResult = 'test_token';

      final result = await repository.login(email: 'test@test.com', password: 'password');

      expect(result.isRight(), true);
      result.fold((_) {}, (token) {
        expect(token, 'test_token');
      });
    });

    test('should return ServerFailure on server exception', () async {
      dataSource.loginError = ServerException('Server error', statusCode: 500);

      final result = await repository.login(email: 'test@test.com', password: 'password');

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Server error');
      }, (_) {});
    });

    test('should return UnauthorizedFailure on unauthorized', () async {
      dataSource.loginError = UnauthorizedException();

      final result = await repository.login(email: 'test@test.com', password: 'password');

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<UnauthorizedFailure>());
      }, (_) {});
    });
  });
}
