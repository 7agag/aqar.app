import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<String> login({
    required String email,
    required String password,
  });

  Future<String> register({
    required String firstName,
    required String secondName,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<UserModel> getProfile();

  Future<void> logout();

  Future<void> verifyOtp({required String email, required String otp});

  Future<void> requestOtp({required String email});

  Future<void> requestPasswordReset({required String email});

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });
}

@Injectable(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final token = response.data['token'] as String;
      return token;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw UnauthorizedException();
      }
      throw ServerException(
        e.response?.data['msg'] ?? 'Something went wrong',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<String> register({
    required String firstName,
    required String secondName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/signup',
        data: {
          'firstName': firstName,
          'secondName': secondName,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );
      return response.data['msg'] ?? 'Registered successfully';
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['msg'] ?? 'Registration failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await apiClient.dio.get('/auth/profile');
      final data = response.data;
      final userJson = data is Map<String, dynamic> && data['user'] != null
          ? data['user'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to get profile',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.dio.post('/auth/logout');
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['msg'] ?? 'Logout failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await apiClient.dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['msg'] ?? 'OTP verification failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> requestOtp({required String email}) async {
    try {
      await apiClient.dio.post(
        '/auth/request-otp',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to send OTP',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      await apiClient.dio.post(
        '/auth/request-reset',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to send password reset email',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await apiClient.dio.post(
        '/auth/reset-password/$token',
        data: {'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to reset password',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
