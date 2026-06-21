import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/entities/lease_entity.dart';

abstract class LeaseRemoteDataSource {
  Future<List<LeaseEntity>> getLeasesAsRenter();
  Future<List<LeaseEntity>> getLeasesAsOwner();
  Future<LeaseEntity> getLeaseById(String leaseId);
}

@Injectable(as: LeaseRemoteDataSource)
class LeaseRemoteDataSourceImpl implements LeaseRemoteDataSource {
  final ApiClient apiClient;
  LeaseRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<LeaseEntity>> getLeasesAsRenter() async {
    try {
      final response = await apiClient.dio.get('/leases/renter');
      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List?;
      if (rawList == null) return const [];
      return rawList
          .cast<Map<String, dynamic>>()
          .map((e) => LeaseEntity.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch renter leases',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<LeaseEntity>> getLeasesAsOwner() async {
    try {
      final response = await apiClient.dio.get('/leases/owner');
      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List?;
      if (rawList == null) return const [];
      return rawList
          .cast<Map<String, dynamic>>()
          .map((e) => LeaseEntity.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch owner leases',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<LeaseEntity> getLeaseById(String leaseId) async {
    try {
      final response = await apiClient.dio.get('/leases/$leaseId');
      final data = response.data as Map<String, dynamic>;
      final dataObj = data['data'] as Map<String, dynamic>? ?? {};
      return LeaseEntity.fromJson(dataObj);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch lease detail',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
