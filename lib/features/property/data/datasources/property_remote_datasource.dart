import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/property_model.dart';

abstract class PropertyRemoteDataSource {
  Future<List<PropertyModel>> getProperties({
    String? location,
    double? minPrice,
    double? maxPrice,
    double? minSize,
    double? maxSize,
    int? bedrooms,
    int? bathrooms,
  });

  Future<PropertyModel> getPropertyById(int id);

  Future<List<PropertyModel>> getMyProperties();
}

@Injectable(as: PropertyRemoteDataSource)
class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  final ApiClient apiClient;
  PropertyRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<PropertyModel>> getProperties({
    String? location,
    double? minPrice,
    double? maxPrice,
    double? minSize,
    double? maxSize,
    int? bedrooms,
    int? bathrooms,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (location != null) queryParams['location'] = location;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (minSize != null) queryParams['minSize'] = minSize;
      if (maxSize != null) queryParams['maxSize'] = maxSize;
      if (bedrooms != null) queryParams['bedrooms'] = bedrooms;
      if (bathrooms != null) queryParams['bathrooms'] = bathrooms;

      final response = await apiClient.dio.get(
        '/property',
        queryParameters: queryParams,
      );

      final List data = response.data as List;
      return data.map((e) => PropertyModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to get properties',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<PropertyModel> getPropertyById(int id) async {
    try {
      final response = await apiClient.dio.get('/property/$id');
      return PropertyModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to get property',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<PropertyModel>> getMyProperties() async {
    try {
      final response = await apiClient.dio.get('/property/my-properties');
      final List data = response.data as List;
      return data.map((e) => PropertyModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['msg'] ?? 'Failed to get my properties',
        statusCode: e.response?.statusCode,
      );
    }
  }
}