import 'package:equatable/equatable.dart';
import '../../domain/entities/property_entity.dart';

abstract class PropertyState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PropertyInitial extends PropertyState {}

class PropertyLoading extends PropertyState {}

class PropertiesLoaded extends PropertyState {
  final List<PropertyEntity> properties;
  PropertiesLoaded(this.properties);

  @override
  List<Object> get props => [properties];
}

class PropertyLoaded extends PropertyState {
  final PropertyEntity property;
  PropertyLoaded(this.property);

  @override
  List<Object> get props => [property];
}

class MyPropertiesLoaded extends PropertyState {
  final List<PropertyEntity> properties;
  MyPropertiesLoaded(this.properties);

  @override
  List<Object> get props => [properties];
}

class PropertyError extends PropertyState {
  final String message;
  PropertyError(this.message);

  @override
  List<Object> get props => [message];
}