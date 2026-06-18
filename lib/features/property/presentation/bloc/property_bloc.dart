import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import 'property_event.dart';
import 'property_state.dart';
import '../../domain/usecases/get_properties_usecase.dart';
import '../../domain/usecases/get_property_by_id_usecase.dart';
import '../../domain/usecases/get_my_properties_usecase.dart';
import '../../domain/entities/property_filter_params.dart';
import '../../domain/entities/property_entity.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';

@injectable
class PropertyBloc extends Bloc<PropertyEvent, PropertyState> {
  final GetPropertiesUseCase getProperties;
  final GetPropertyByIdUseCase getPropertyById;
  final GetMyPropertiesUseCase getMyProperties;

  PropertyBloc(
    this.getProperties,
    this.getPropertyById,
    this.getMyProperties,
  ) : super(PropertyInitial()) {

    on<GetPropertiesRequested>((event, emit) async {
      emit(PropertyLoading());

      final result = await getProperties(event.params);

      result.fold(
        (failure) => emit(PropertyError(failure.message)),
        (properties) => emit(PropertiesLoaded(allProperties: properties)),
      );
    });

    on<GetPropertyByIdRequested>((event, emit) async {
      emit(PropertyLoading());

      final result = await getPropertyById(
        GetPropertyByIdParams(id: event.id),
      );

      result.fold(
        (failure) => emit(PropertyError(failure.message)),
        (property) => emit(PropertyDetailLoaded(property)),
      );
    });

    on<GetMyPropertiesRequested>((event, emit) async {
      emit(PropertyLoading());

      final result = await getMyProperties(NoParams());

      result.fold(
        (failure) => emit(PropertyError(failure.message)),
        (properties) => emit(MyPropertiesLoaded(properties)),
      );
    });
  }

  Future<Either<Failure, List<PropertyEntity>>> getPropertiesDirectly(
    PropertyFilterParams params,
  ) async {
    return await getProperties(params);
  }
}