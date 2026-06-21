import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/features/property/domain/entities/property_enums.dart';
import 'package:aqar/features/property/domain/entities/property_filter_params.dart';
import 'package:aqar/features/property/domain/repositories/property_repository.dart';
import 'package:aqar/features/property/domain/usecases/get_properties_usecase.dart';

class MockPropertyRepository extends PropertyRepository {
  Either<Failure, List<PropertyEntity>> _result = Right(<PropertyEntity>[]);

  void setResult(Either<Failure, List<PropertyEntity>> result) => _result = result;

  @override
  Future<Either<Failure, List<PropertyEntity>>> getProperties(PropertyFilterParams params) async => _result;

  @override
  Future<Either<Failure, PropertyEntity>> getPropertyById(int id) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<PropertyEntity>>> getMyProperties() async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> addProperty(FormData formData) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> editProperty(int id, Map<String, dynamic> data) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> editPropertyImages(int id, FormData formData) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deleteProperty(int id) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getBookedDates(int id) async => throw UnimplementedError();
}

PropertyEntity _createProperty(int id) {
  return PropertyEntity(
    propertyId: id,
    ownerId: 'owner1',
    propertyName: 'Test Property $id',
    propertyDesc: 'A test property',
    location: 'Test Location',
    pricingUnit: PricingUnit.month,
    priceValue: 1000.0,
    pricePerDay: 50.0,
    size: '120 sqm',
    bedroomsNo: 3,
    bedsNo: 2,
    bathroomsNo: 2,
    images: ['image1.jpg'],
    isVerified: true,
    isAvailable: true,
    isFurnished: true,
    listingType: ListingType.forSale,
    physicalType: PhysicalPropertyType.apartment,
    rate: 4.5,
    listingStatus: ListingStatus.active,
  );
}

void main() {
  late GetPropertiesUseCase useCase;
  late MockPropertyRepository repository;

  setUp(() {
    repository = MockPropertyRepository();
    useCase = GetPropertiesUseCase(repository);
  });

  final params = const PropertyFilterParams();

  test('should return list of properties on success', () async {
    final properties = [_createProperty(1), _createProperty(2)];
    repository.setResult(Right(properties));

    final result = await useCase(params);

    expect(result.isRight(), true);
    result.fold((_) {}, (props) {
      expect(props.length, 2);
      expect(props.first.propertyName, 'Test Property 1');
    });
  });

  test('should return empty list on no properties', () async {
    repository.setResult(const Right(<PropertyEntity>[]));

    final result = await useCase(params);

    expect(result.isRight(), true);
    result.fold((_) {}, (props) {
      expect(props, isEmpty);
    });
  });

  test('should return failure on error', () async {
    repository.setResult(const Left(ServerFailure('Server error')));

    final result = await useCase(params);

    expect(result.isLeft(), true);
    result.fold((failure) {
      expect(failure.message, 'Server error');
    }, (_) {});
  });
}
