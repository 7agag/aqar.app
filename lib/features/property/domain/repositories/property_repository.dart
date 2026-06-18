import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/property_entity.dart';
import '../entities/property_filter_params.dart';

abstract class PropertyRepository {
  Future<Either<Failure, List<PropertyEntity>>> getProperties(
    PropertyFilterParams params,
  );

  Future<Either<Failure, PropertyEntity>> getPropertyById(int id);

  Future<Either<Failure, List<PropertyEntity>>> getMyProperties();
  }