import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice_entity.dart';

abstract class InvoiceState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {}

class InvoiceLoading extends InvoiceState {}

class RenterInvoicesLoaded extends InvoiceState {
  final List<InvoiceEntity> invoices;
  final InvoiceStatsEntity? stats;
  RenterInvoicesLoaded({required this.invoices, this.stats});
  @override
  List<Object?> get props => [invoices, stats];
}

class OwnerInvoicesLoaded extends InvoiceState {
  final List<InvoiceEntity> invoices;
  final InvoiceStatsEntity? stats;
  OwnerInvoicesLoaded({required this.invoices, this.stats});
  @override
  List<Object?> get props => [invoices, stats];
}

class InvoiceError extends InvoiceState {
  final String message;
  InvoiceError(this.message);
  @override
  List<Object?> get props => [message];
}
