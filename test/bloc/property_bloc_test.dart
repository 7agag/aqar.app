import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/core/usecases/usecase.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/features/property/domain/entities/property_filter_params.dart';
import 'package:aqar/features/property/domain/repositories/property_repository.dart';
import 'package:aqar/features/property/domain/usecases/get_properties_usecase.dart';
import 'package:aqar/features/property/domain/usecases/get_property_by_id_usecase.dart';
import 'package:aqar/features/property/domain/usecases/get_my_properties_usecase.dart';
import 'package:aqar/features/property/presentation/bloc/property_bloc.dart';
import 'package:aqar/features/property/presentation/bloc/property_event.dart';
import 'package:aqar/features/property/presentation/bloc/property_state.dart';

class MockGetPropertiesUseCase extends GetPropertiesUseCase {
  MockGetPropertiesUseCase() : super(MockPropertyRepo());

  Either<Failure, List<PropertyEntity>> result = Right(<PropertyEntity>[]);

  @override
  Future<Either<Failure, List<PropertyEntity>>> call(covariant PropertyFilterParams params) async => result;
}

class MockPropertyRepo extends PropertyRepository {
  @override
  Future<Either<Failure, List<PropertyEntity>>> getProperties(PropertyFilterParams params) async => const Right([]);
  @override
  Future<Either<Failure, PropertyEntity>> getPropertyById(int id) async => throw UnimplementedError();
  @override
  Future<Either<Failure, List<PropertyEntity>>> getMyProperties() async => throw UnimplementedError();
}

PropertyEntity _createProperty(int id) {
  return PropertyEntity(
    propertyId: id,
    ownerId: 'owner1',
    propertyName: 'Property $id',
    propertyDesc: 'Description $id',
    location: 'Location $id',
    pricingUnit: 'MONTH',
    priceValue: 1000.0,
    pricePerDay: 50.0,
    size: '100 sqm',
    bedroomsNo: 3,
    bedsNo: 2,
    bathroomsNo: 2,
    images: ['img.jpg'],
    isVerified: true,
    isAvailable: true,
    isFurnished: false,
    propertyType: 'apartment',
    rate: 4.0,
    listingStatus: 'for_sale',
  );
}

void main() {
  late PropertyBloc propertyBloc;
  late MockGetPropertiesUseCase mockGetProperties;

  setUp(() {
    mockGetProperties = MockGetPropertiesUseCase();
    propertyBloc = PropertyBloc(
      mockGetProperties,
      MockGetPropertyById(),
      MockGetMyProperties(),
    );
  });

  tearDown(() {
    propertyBloc.close();
  });

  blocTest<PropertyBloc, PropertyState>(
    'emits [PropertyLoading, PropertiesLoaded] when properties are fetched',
    build: () {
      mockGetProperties.result = Right([_createProperty(1), _createProperty(2)]);
      return propertyBloc;
    },
    act: (bloc) => bloc.add(GetPropertiesRequested(params: PropertyFilterParams())),
    expect: () => [
      isA<PropertyLoading>(),
      isA<PropertiesLoaded>(),
    ],
  );

  blocTest<PropertyBloc, PropertyState>(
    'emits [PropertyLoading, PropertyError] when fetch fails',
    build: () {
      mockGetProperties.result = const Left(ServerFailure('Failed'));
      return propertyBloc;
    },
    act: (bloc) => bloc.add(GetPropertiesRequested(params: PropertyFilterParams())),
    expect: () => [
      isA<PropertyLoading>(),
      isA<PropertyError>(),
    ],
  );
}

class MockGetPropertyById extends GetPropertyByIdUseCase {
  MockGetPropertyById() : super(MockPropertyRepo());
  @override
  Future<Either<Failure, PropertyEntity>> call(GetPropertyByIdParams params) async => throw UnimplementedError();
}

class MockGetMyProperties extends GetMyPropertiesUseCase {
  MockGetMyProperties() : super(MockPropertyRepo());
  @override
  Future<Either<Failure, List<PropertyEntity>>> call(NoParams params) async => throw UnimplementedError();
}

