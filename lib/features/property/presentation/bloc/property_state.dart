import 'package:equatable/equatable.dart';
import '../../domain/entities/property_entity.dart';

abstract class PropertyState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PropertyInitial extends PropertyState {}

class PropertyLoading extends PropertyState {}

class PropertiesLoaded extends PropertyState {
  final List<PropertyEntity> allProperties;

  PropertiesLoaded({required this.allProperties});

  @override
  List<Object?> get props => [allProperties];
}

class PropertyDetailLoaded extends PropertyState {
  final PropertyEntity property;
  PropertyDetailLoaded(this.property);
  @override
  List<Object?> get props => [property];
}

class MyPropertiesLoaded extends PropertyState {
  final List<PropertyEntity> properties;
  MyPropertiesLoaded(this.properties);
  @override
  List<Object?> get props => [properties];
}

class PropertyOperationSuccess extends PropertyState {
  final String message;
  PropertyOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class PropertyDeleted extends PropertyState {
  final int propertyId;
  final String message;
  PropertyDeleted(this.propertyId, this.message);
  @override
  List<Object?> get props => [propertyId, message];
}

class PropertyError extends PropertyState {
  final String message;
  PropertyError(this.message);
  @override
  List<Object?> get props => [message];
}

