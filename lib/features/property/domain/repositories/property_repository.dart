import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../core/error/failures.dart';
import '../entities/property_entity.dart';
import '../entities/property_filter_params.dart';

abstract class PropertyRepository {
  Future<Either<Failure, List<PropertyEntity>>> getProperties(
    PropertyFilterParams params,
  );

  Future<Either<Failure, PropertyEntity>> getPropertyById(int id);

  Future<Either<Failure, List<PropertyEntity>>> getMyProperties();

  Future<Either<Failure, void>> addProperty(FormData formData);

  Future<Either<Failure, void>> editProperty(int id, Map<String, dynamic> data);

  Future<Either<Failure, void>> editPropertyImages(int id, FormData formData);

  Future<Either<Failure, void>> deleteProperty(int id);

  Future<Either<Failure, List<Map<String, dynamic>>>> getBookedDates(int id);
}