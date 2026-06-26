import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import 'property_event.dart';
import 'property_state.dart';
import '../../domain/usecases/get_properties_usecase.dart';
import '../../domain/usecases/get_property_by_id_usecase.dart';
import '../../domain/usecases/get_my_properties_usecase.dart';
import '../../domain/usecases/add_property_usecase.dart';
import '../../domain/usecases/edit_property_usecase.dart';
import '../../domain/usecases/edit_property_images_usecase.dart';
import '../../domain/usecases/delete_property_usecase.dart';
import '../../domain/entities/property_filter_params.dart';
import '../../domain/entities/property_entity.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';

@injectable
class PropertyBloc extends Bloc<PropertyEvent, PropertyState> {
  final GetPropertiesUseCase getProperties;
  final GetPropertyByIdUseCase getPropertyById;
  final GetMyPropertiesUseCase getMyProperties;
  final AddPropertyUseCase addProperty;
  final EditPropertyUseCase editProperty;
  final EditPropertyImagesUseCase editPropertyImages;
  final DeletePropertyUseCase deleteProperty;

  PropertyBloc({
    required this.getProperties,
    required this.getPropertyById,
    required this.getMyProperties,
    required this.addProperty,
    required this.editProperty,
    required this.editPropertyImages,
    required this.deleteProperty,
  }) : super(PropertyInitial()) {

    on<GetPropertiesRequested>((event, emit) async {
      emit(PropertyLoading());
      final result = await getProperties(event.params);
      result.fold(
        (failure) => emit(PropertyError(failure.message)),
        (properties) => emit(PropertiesLoaded(allProperties: properties.where((p) => p.isPubliclyVisible).toList())),
      );
    });

    on<GetPropertyByIdRequested>((event, emit) async {
      emit(PropertyLoading());
      final result = await getPropertyById(GetPropertyByIdParams(id: event.id));
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

    on<AddPropertyRequested>((event, emit) async {
      emit(PropertyLoading());
      final result = await addProperty(event.formData);
      result.fold(
        (failure) => emit(PropertyError(failure.message)),
        (_) => emit(PropertyOperationSuccess('Property added successfully')),
      );
    });

    on<EditPropertyRequested>((event, emit) async {
      emit(PropertyLoading());
      final result = await editProperty(EditPropertyParams(id: event.id, data: event.data));
      result.fold(
        (failure) => emit(PropertyError(failure.message)),
        (_) => emit(PropertyOperationSuccess('Property updated successfully')),
      );
    });

    on<EditPropertyImagesRequested>((event, emit) async {
      emit(PropertyLoading());
      final result = await editPropertyImages(EditPropertyImagesParams(id: event.id, formData: event.formData));
      result.fold(
        (failure) => emit(PropertyError(failure.message)),
        (_) => emit(PropertyOperationSuccess('Property images updated')),
      );
    });

    on<DeletePropertyRequested>((event, emit) async {
      emit(PropertyLoading());
      final result = await deleteProperty(event.id);
      result.fold(
        (failure) => emit(PropertyError(failure.message)),
        (_) => emit(PropertyDeleted(event.id, 'Property deleted successfully')),
      );
    });
  }

  Future<Either<Failure, List<PropertyEntity>>> getPropertiesDirectly(
    PropertyFilterParams params,
  ) async {
    return await getProperties(params);
  }
}
