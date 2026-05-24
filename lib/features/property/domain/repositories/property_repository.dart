import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/property_entity.dart';

abstract class PropertyRepository {
  Future<Either<Failure, List<PropertyEntity>>> getProperties({
    String? location,
    double? minPrice,
    double? maxPrice,
    double? minSize,
    double? maxSize,
    int? bedrooms,
    int? bathrooms,
    String? propertyType,
  });

  Future<Either<Failure, PropertyEntity>> getPropertyById(int id);

  Future<Either<Failure, List<PropertyEntity>>> getMyProperties();
}
