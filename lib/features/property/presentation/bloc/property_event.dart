import 'package:dio/dio.dart';
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

class AddPropertyRequested extends PropertyEvent {
  final FormData formData;
  const AddPropertyRequested({required this.formData});
  @override
  List<Object?> get props => [formData];
}

class EditPropertyRequested extends PropertyEvent {
  final int id;
  final Map<String, dynamic> data;
  const EditPropertyRequested({required this.id, required this.data});
  @override
  List<Object?> get props => [id, data];
}

class EditPropertyImagesRequested extends PropertyEvent {
  final int id;
  final FormData formData;
  const EditPropertyImagesRequested({required this.id, required this.formData});
  @override
  List<Object?> get props => [id, formData];
}

class DeletePropertyRequested extends PropertyEvent {
  final int id;
  const DeletePropertyRequested({required this.id});
  @override
  List<Object?> get props => [id];
}
