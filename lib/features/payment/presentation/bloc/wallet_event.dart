import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class GetWalletDataRequested extends WalletEvent {
  const GetWalletDataRequested();
}

class RequestWithdrawalTriggered extends WalletEvent {
  final double amount;
  final String method;
  final String receiverData;
  const RequestWithdrawalTriggered({
    required this.amount,
    required this.method,
    required this.receiverData,
  });
  @override
  List<Object?> get props => [amount, method, receiverData];
}
