import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'invoice_event.dart';
import 'invoice_state.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/usecases/get_renter_invoices_usecase.dart';
import '../../domain/usecases/get_owner_invoices_usecase.dart';
import '../../domain/usecases/get_invoice_stats_usecase.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';

@injectable
class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final GetRenterInvoicesUseCase getRenterInvoices;
  final GetOwnerInvoicesUseCase getOwnerInvoices;
  final GetInvoiceStatsUseCase getInvoiceStats;

  InvoiceBloc({
    required this.getRenterInvoices,
    required this.getOwnerInvoices,
    required this.getInvoiceStats,
  }) : super(InvoiceInitial()) {

    on<GetRenterInvoicesRequested>((event, emit) async {
      emit(InvoiceLoading());
      final results = await Future.wait([
        getRenterInvoices(NoParams()),
        getInvoiceStats(NoParams()),
      ]);
      final invoicesResult = results[0] as Either<Failure, List<InvoiceEntity>>;
      final statsResult = results[1] as Either<Failure, InvoiceStatsEntity>;
      invoicesResult.fold(
        (failure) => emit(InvoiceError(failure.message)),
        (invoices) {
          InvoiceStatsEntity? stats;
          statsResult.fold((_) => null, (s) => stats = s);
          emit(RenterInvoicesLoaded(invoices: invoices, stats: stats));
        },
      );
    });

    on<GetOwnerInvoicesRequested>((event, emit) async {
      emit(InvoiceLoading());
      final results = await Future.wait([
        getOwnerInvoices(NoParams()),
        getInvoiceStats(NoParams()),
      ]);
      final invoicesResult = results[0] as Either<Failure, List<InvoiceEntity>>;
      final statsResult = results[1] as Either<Failure, InvoiceStatsEntity>;
      invoicesResult.fold(
        (failure) => emit(InvoiceError(failure.message)),
        (invoices) {
          InvoiceStatsEntity? stats;
          statsResult.fold((_) => null, (s) => stats = s);
          emit(OwnerInvoicesLoaded(invoices: invoices, stats: stats));
        },
      );
    });
  }
}
