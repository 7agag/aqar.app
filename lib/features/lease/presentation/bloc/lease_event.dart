import 'package:equatable/equatable.dart';

abstract class LeaseEvent extends Equatable {
  const LeaseEvent();
  @override
  List<Object?> get props => [];
}

class GetRenterLeasesRequested extends LeaseEvent {
  const GetRenterLeasesRequested();
}

class GetOwnerLeasesRequested extends LeaseEvent {
  const GetOwnerLeasesRequested();
}

class GetLeaseDetailRequested extends LeaseEvent {
  final String leaseId;
  const GetLeaseDetailRequested({required this.leaseId});
  @override
  List<Object?> get props => [leaseId];
}
