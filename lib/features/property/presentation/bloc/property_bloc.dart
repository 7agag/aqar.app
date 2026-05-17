import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_properties_usecase.dart';
import '../../domain/usecases/get_property_by_id_usecase.dart';
import '../../domain/usecases/get_my_properties_usecase.dart';
import 'property_event.dart';
import 'property_state.dart';

@injectable
class PropertyBloc extends Bloc<PropertyEvent, PropertyState> {
  final GetPropertiesUseCase getPropertiesUseCase;
  final GetPropertyByIdUseCase getPropertyByIdUseCase;
  final GetMyPropertiesUseCase getMyPropertiesUseCase;

  PropertyBloc({
    required this.getPropertiesUseCase,
    required this.getPropertyByIdUseCase,
    required this.getMyPropertiesUseCase,
  }) : super(PropertyInitial()) {
    on<GetPropertiesRequested>(_onGetProperties);
    on<GetPropertyByIdRequested>(_onGetPropertyById);
    on<GetMyPropertiesRequested>(_onGetMyProperties);
  }

  Future<void> _onGetProperties(
    GetPropertiesRequested event,
    Emitter<PropertyState> emit,
  ) async {
    emit(PropertyLoading());
    final result = await getPropertiesUseCase(
      GetPropertiesParams(
        location: event.location,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        minSize: event.minSize,
        maxSize: event.maxSize,
        bedrooms: event.bedrooms,
        bathrooms: event.bathrooms,
      ),
    );
    result.fold(
      (failure) => emit(PropertyError(failure.message)),
      (properties) => emit(PropertiesLoaded(properties)),
    );
  }

  Future<void> _onGetPropertyById(
    GetPropertyByIdRequested event,
    Emitter<PropertyState> emit,
  ) async {
    emit(PropertyLoading());
    final result = await getPropertyByIdUseCase(
      GetPropertyByIdParams(id: event.id),
    );
    result.fold(
      (failure) => emit(PropertyError(failure.message)),
      (property) => emit(PropertyLoaded(property)),
    );
  }

  Future<void> _onGetMyProperties(
    GetMyPropertiesRequested event,
    Emitter<PropertyState> emit,
  ) async {
    emit(PropertyLoading());
    final result = await getMyPropertiesUseCase(const NoParams());
    result.fold(
      (failure) => emit(PropertyError(failure.message)),
      (properties) => emit(MyPropertiesLoaded(properties)),
    );
  }
}