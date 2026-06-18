import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/network/api_client.dart';
import '../models/property_model.dart';
import '../../domain/entities/property_filter_params.dart';

abstract class PropertyRemoteDataSource {
  Future<List<PropertyModel>> getProperties(PropertyFilterParams params);
  Future<PropertyModel> getPropertyById(int id);
  Future<List<PropertyModel>> getMyProperties();
}

@Injectable(as: PropertyRemoteDataSource)
class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  final ApiClient apiClient;
  PropertyRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<PropertyModel>> getProperties(PropertyFilterParams params) async {
    try {
      final response = await apiClient.dio.get(
        '/property',
        queryParameters: params.toJson(),
      );
      final List data = response.data as List;
      return data
          .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to fetch properties',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<PropertyModel> getPropertyById(int id) async {
    try {
      final response = await apiClient.dio.get('/property/$id');
      return PropertyModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ServerException('Property not found', statusCode: 404);
      }
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to fetch property',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<PropertyModel>> getMyProperties() async {
    try {
      final response = await apiClient.dio.get('/property/my-properties');
      final List data = response.data as List;
      return data
          .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to fetch my properties',
        statusCode: e.response?.statusCode,
      );
    }
  }
}