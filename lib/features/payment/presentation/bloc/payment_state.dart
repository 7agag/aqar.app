import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_entity.dart';

abstract class PaymentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentLinkReady extends PaymentState {
  final PaymentLinkEntity paymentLink;
  PaymentLinkReady({required this.paymentLink});
  @override
  List<Object?> get props => [paymentLink];
}

class PaymentError extends PaymentState {
  final String message;
  PaymentError(this.message);
  @override
  List<Object?> get props => [message];
}
