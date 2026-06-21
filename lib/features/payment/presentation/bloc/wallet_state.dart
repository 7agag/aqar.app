import 'package:equatable/equatable.dart';
import '../../domain/entities/balance_entity.dart';
import '../../domain/entities/payment_entity.dart';

abstract class WalletState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final BalanceEntity balance;
  final List<TransactionEntity> transactions;
  WalletLoaded({
    required this.balance,
    required this.transactions,
  });
  @override
  List<Object?> get props => [balance, transactions];
}

class WalletError extends WalletState {
  final String message;
  WalletError(this.message);
  @override
  List<Object?> get props => [message];
}
