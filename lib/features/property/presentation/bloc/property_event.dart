import 'package:equatable/equatable.dart';

abstract class PropertyEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetPropertiesRequested extends PropertyEvent {
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final double? minSize;
  final double? maxSize;
  final int? bedrooms;
  final int? bathrooms;

  GetPropertiesRequested({
    this.location,
    this.minPrice,
    this.maxPrice,
    this.minSize,
    this.maxSize,
    this.bedrooms,
    this.bathrooms,
  });

  @override
  List<Object?> get props => [location, minPrice, maxPrice, bedrooms];
}

class GetPropertyByIdRequested extends PropertyEvent {
  final int id;
  GetPropertyByIdRequested({required this.id});

  @override
  List<Object> get props => [id];
}

class GetMyPropertiesRequested extends PropertyEvent {}