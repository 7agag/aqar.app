import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'lease_event.dart';
import 'lease_state.dart';
import '../../domain/usecases/get_renter_leases_usecase.dart';
import '../../domain/usecases/get_owner_leases_usecase.dart';
import '../../domain/usecases/get_lease_detail_usecase.dart';
import '../../../../../core/usecases/usecase.dart';

@injectable
class LeaseBloc extends Bloc<LeaseEvent, LeaseState> {
  final GetRenterLeasesUseCase getRenterLeases;
  final GetOwnerLeasesUseCase getOwnerLeases;
  final GetLeaseDetailUseCase getLeaseDetail;

  LeaseBloc({
    required this.getRenterLeases,
    required this.getOwnerLeases,
    required this.getLeaseDetail,
  }) : super(LeaseInitial()) {

    on<GetRenterLeasesRequested>((event, emit) async {
      emit(LeaseLoading());
      final result = await getRenterLeases(NoParams());
      result.fold(
        (failure) => emit(LeaseError(failure.message)),
        (leases) => emit(RenterLeasesLoaded(leases: leases)),
      );
    });

    on<GetOwnerLeasesRequested>((event, emit) async {
      emit(LeaseLoading());
      final result = await getOwnerLeases(NoParams());
      result.fold(
        (failure) => emit(LeaseError(failure.message)),
        (leases) => emit(OwnerLeasesLoaded(leases: leases)),
      );
    });

    on<GetLeaseDetailRequested>((event, emit) async {
      emit(LeaseLoading());
      final result = await getLeaseDetail(
        GetLeaseDetailParams(leaseId: event.leaseId),
      );
      result.fold(
        (failure) => emit(LeaseError(failure.message)),
        (lease) => emit(LeaseDetailLoaded(lease: lease)),
      );
    });
  }
}
