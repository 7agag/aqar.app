import 'package:equatable/equatable.dart';
import '../../domain/entities/lease_entity.dart';

abstract class LeaseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LeaseInitial extends LeaseState {}

class LeaseLoading extends LeaseState {}

class RenterLeasesLoaded extends LeaseState {
  final List<LeaseEntity> leases;
  RenterLeasesLoaded({required this.leases});
  @override
  List<Object?> get props => [leases];
}

class OwnerLeasesLoaded extends LeaseState {
  final List<LeaseEntity> leases;
  OwnerLeasesLoaded({required this.leases});
  @override
  List<Object?> get props => [leases];
}

class LeaseDetailLoaded extends LeaseState {
  final LeaseEntity lease;
  LeaseDetailLoaded({required this.lease});
  @override
  List<Object?> get props => [lease];
}

class LeaseError extends LeaseState {
  final String message;
  LeaseError(this.message);
  @override
  List<Object?> get props => [message];
}
