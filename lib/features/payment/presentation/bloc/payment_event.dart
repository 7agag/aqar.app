import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class GetPaymentLinkRequested extends PaymentEvent {
  final String? requestId;
  final String? invoiceId;
  final String? subscriptionId;
  final String? redirect;
  const GetPaymentLinkRequested({
    this.requestId,
    this.invoiceId,
    this.subscriptionId,
    this.redirect,
  });
  @override
  List<Object?> get props =>
      [requestId, invoiceId, subscriptionId, redirect];
}
