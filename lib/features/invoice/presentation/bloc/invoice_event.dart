import 'package:equatable/equatable.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class GetRenterInvoicesRequested extends InvoiceEvent {
  const GetRenterInvoicesRequested();
}

class GetOwnerInvoicesRequested extends InvoiceEvent {
  const GetOwnerInvoicesRequested();
}

class GetInvoiceStatsRequested extends InvoiceEvent {
  const GetInvoiceStatsRequested();
}
