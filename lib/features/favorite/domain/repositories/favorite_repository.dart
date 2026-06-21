import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../property/domain/entities/property_entity.dart';

abstract class FavoriteRepository {
  Future<Either<Failure, void>> addToFavorites(int propertyId);
  Future<Either<Failure, void>> removeFromFavorites(int propertyId);
  Future<Either<Failure, List<PropertyEntity>>> getUserFavorites();
  Future<Either<Failure, List<PropertyEntity>>> compareFavorites(List<int> propertyIds);
}