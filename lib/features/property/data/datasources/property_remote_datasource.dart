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
  Future<void> addProperty(FormData formData);
  Future<void> editProperty(int id, Map<String, dynamic> data);
  Future<void> editPropertyImages(int id, FormData formData);
  Future<void> deleteProperty(int id);
  Future<List<Map<String, dynamic>>> getBookedDates(int id);
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
    } catch (e) {
      throw ServerException('Failed to parse properties: $e');
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
    } catch (e) {
      throw ServerException('Failed to parse property: $e');
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
    } catch (e) {
      throw ServerException('Failed to parse my properties: $e');
    }
  }

  @override
  Future<void> addProperty(FormData formData) async {
    try {
      await apiClient.dio.post('/property', data: formData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) throw UnauthorizedException();
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to add property',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> editProperty(int id, Map<String, dynamic> data) async {
    try {
      await apiClient.dio.put('/property/$id', data: data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) throw UnauthorizedException();
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to update property',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> editPropertyImages(int id, FormData formData) async {
    try {
      await apiClient.dio.put('/property/$id/images', data: formData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) throw UnauthorizedException();
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to update property images',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteProperty(int id) async {
    try {
      await apiClient.dio.delete('/property/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) throw UnauthorizedException();
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to delete property',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBookedDates(int id) async {
    try {
      final response = await apiClient.dio.get('/properties/$id/booked-dates');
      final data = response.data as Map<String, dynamic>?;
      final raw = data?['data'];
      if (raw == null || raw is! List) return [];
      return raw.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to fetch booked dates',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
