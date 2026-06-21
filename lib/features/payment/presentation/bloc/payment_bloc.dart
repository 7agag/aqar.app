import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'payment_event.dart';
import 'payment_state.dart';
import '../../domain/usecases/get_payment_link_usecase.dart';

@injectable
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final GetPaymentLinkUseCase getPaymentLink;

  PaymentBloc({
    required this.getPaymentLink,
  }) : super(PaymentInitial()) {

    on<GetPaymentLinkRequested>((event, emit) async {
      emit(PaymentLoading());
      final result = await getPaymentLink(GetPaymentLinkParams(
        requestId: event.requestId,
        invoiceId: event.invoiceId,
        subscriptionId: event.subscriptionId,
        redirect: event.redirect,
      ));
      result.fold(
        (failure) => emit(PaymentError(failure.message)),
        (link) => emit(PaymentLinkReady(paymentLink: link)),
      );
    });
  }
}
