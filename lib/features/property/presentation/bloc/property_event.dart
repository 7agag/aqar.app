// lib/features/property/presentation/bloc/property_event.dart

import 'package:equatable/equatable.dart';

import '../../domain/entities/property_filter_params.dart';

abstract class PropertyEvent extends Equatable {
  const PropertyEvent();
  @override
  List<Object?> get props => [];
}

class GetPropertiesRequested extends PropertyEvent {
  final PropertyFilterParams params;
  const GetPropertiesRequested({required this.params});
  @override
  List<Object?> get props => [params];
}

class GetPropertyByIdRequested extends PropertyEvent {
  final int id;
  const GetPropertyByIdRequested({required this.id});
  @override
  List<Object?> get props => [id];
}

class GetMyPropertiesRequested extends PropertyEvent {
  const GetMyPropertiesRequested();
}
