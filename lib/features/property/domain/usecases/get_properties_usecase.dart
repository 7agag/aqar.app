import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/property_entity.dart';
import '../repositories/property_repository.dart';

@injectable
class GetPropertiesUseCase
    extends UseCase<List<PropertyEntity>, GetPropertiesParams> {
  final PropertyRepository repository;
  GetPropertiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<PropertyEntity>>> call(
    GetPropertiesParams params,
  ) {
    return repository.getProperties(
      location: params.location,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      minSize: params.minSize,
      maxSize: params.maxSize,
      bedrooms: params.bedrooms,
      bathrooms: params.bathrooms,
      propertyType: params.propertyType,
    );
  }
}

class GetPropertiesParams extends Equatable {
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final double? minSize;
  final double? maxSize;
  final int? bedrooms;
  final int? bathrooms;
  final String? propertyType;

  const GetPropertiesParams({
    this.location,
    this.minPrice,
    this.maxPrice,
    this.minSize,
    this.maxSize,
    this.bedrooms,
    this.bathrooms,
    this.propertyType,
  });

  @override
  List<Object?> get props => [
        location,
        minPrice,
        maxPrice,
        minSize,
        maxSize,
        bedrooms,
        bathrooms,
        propertyType,
      ];
}
