import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../property/data/models/property_model.dart';

abstract class FavoriteRemoteDataSource {
  Future<void> addToFavorites(int propertyId);
  Future<void> removeFromFavorites(int propertyId);
  Future<List<PropertyModel>> getUserFavorites();
}

@Injectable(as: FavoriteRemoteDataSource)
class FavoriteRemoteDataSourceImpl implements FavoriteRemoteDataSource {
  final ApiClient apiClient;

  FavoriteRemoteDataSourceImpl(this.apiClient);

  @override
  Future<void> addToFavorites(int propertyId) async {
    try {
      await apiClient.dio.post('/favorites/$propertyId');
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to add to favorites',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> removeFromFavorites(int propertyId) async {
    try {
      await apiClient.dio.delete('/favorites/$propertyId');
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to remove from favorites',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<PropertyModel>> getUserFavorites() async {
    try {
      final response = await apiClient.dio.get('/favorites');
      // backend returns { favorites: [...] }
      final data = response.data;
      if (data is Map && data.containsKey('favorites')) {
        final List favoritesList = data['favorites'];
        return favoritesList
            .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch favorites',
        statusCode: e.response?.statusCode,
      );
    }
  }
}